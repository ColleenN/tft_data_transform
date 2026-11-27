-- A board's core units are its most itemized carries and tanks, counting
-- full items only (everything but loose components; emblems count). A unit
-- is a tank when its role is a tank role, and a carry otherwise, fighters
-- included. The main unit on each side holds the most full items; a second
-- unit on that side with 2 or more is its secondary. The main carry's cost
-- sets the leveling pattern (seed_leveling_patterns), from cost alone, so
-- reroll attempts that never hit their 3-star stay in their pattern. Before
-- var('leveling_pattern_from_stage'), nearly every board itemizes cheap
-- units, so the pattern is undetermined.

WITH unit_items AS (
    SELECT
        match_id, puuid, character_id, tier, unit_instance_index,
        COUNTIF(IFNULL(num_components, 0) = 0) AS full_items
    FROM {{ ref('seed_annotated_unit_items') }}
    GROUP BY match_id, puuid, character_id, tier, unit_instance_index
),

itemized_units AS (
    SELECT
        units.match_id, units.puuid, units.character_id, units.tier, units.rarity AS cost,
        unit_items.full_items,
        IF(units.role LIKE '%Tank%', 'tank', 'carry') AS side
    FROM            {{ ref('seed_annotated_units') }} AS units
        INNER JOIN  unit_items USING (match_id, puuid, character_id, tier, unit_instance_index)
    WHERE units.shop_unit AND unit_items.full_items > 0
),

ranked AS (
    SELECT
        match_id, puuid, side,
        ARRAY_AGG(
            STRUCT(character_id, cost, tier, full_items)
            ORDER BY full_items DESC, tier DESC, cost DESC, character_id
            LIMIT 2
        ) AS top_units
    FROM itemized_units
    GROUP BY match_id, puuid, side
),

carries AS (SELECT match_id, puuid, top_units FROM ranked WHERE side = 'carry'),
tanks AS (SELECT match_id, puuid, top_units FROM ranked WHERE side = 'tank')

SELECT
    boards.match_id,
    boards.puuid,
    boards.tft_set_number,
    {% for side in ['carry', 'tank'] %}
    {{ side }}_units.top_units[SAFE_OFFSET(0)].character_id AS main_{{ side }}_character_id,
    {{ side }}_units.top_units[SAFE_OFFSET(0)].cost AS main_{{ side }}_cost,
    {{ side }}_units.top_units[SAFE_OFFSET(0)].tier AS main_{{ side }}_tier,
    {{ side }}_units.top_units[SAFE_OFFSET(0)].full_items AS main_{{ side }}_full_items,
    IF({{ side }}_units.top_units[SAFE_OFFSET(1)].full_items >= 2,
        {{ side }}_units.top_units[SAFE_OFFSET(1)].character_id, NULL) AS secondary_{{ side }}_character_id,
    IF({{ side }}_units.top_units[SAFE_OFFSET(1)].full_items >= 2,
        {{ side }}_units.top_units[SAFE_OFFSET(1)].full_items, NULL) AS secondary_{{ side }}_full_items,
    {% endfor %}
    CASE
        WHEN schedule.stage < {{ var('leveling_pattern_from_stage', 4) }} THEN 'undetermined'
        WHEN carry_units.top_units IS NULL THEN 'no_carry'
        ELSE IFNULL(patterns.leveling_pattern, 'unclassified')
    END AS leveling_pattern
FROM            {{ ref('seed_annotated_boards') }} AS boards
    LEFT JOIN   carries AS carry_units USING (match_id, puuid)
    LEFT JOIN   tanks AS tank_units USING (match_id, puuid)
    LEFT JOIN   {{ ref('seed_round_schedule') }} AS schedule
        ON schedule.set_num = boards.tft_set_number
        AND schedule.round_num = boards.last_round
    LEFT JOIN   {{ ref('seed_leveling_patterns') }} AS patterns
        ON patterns.set_num = boards.tft_set_number
        AND patterns.carry_cost = carry_units.top_units[SAFE_OFFSET(0)].cost
