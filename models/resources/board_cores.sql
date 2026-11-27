-- A board's units split into its core and its cap, counting full items only
-- (everything but loose components; emblems count). A unit is a tank when its
-- role is a tank role, and a carry otherwise, fighters included.
--
-- Comps have a core, plus carries they cap with when they have the resources
-- to spare. Caps cost more than the core, so the cheapest carry with at least
-- var('core_min_full_items') full items sets the core's cost, and any carry
-- with that many items costing more (and at least var('cap_min_cost')) is a
-- cap. Pricier units holding a single item are usually item holders or
-- utility, not caps.
-- The cost floor keeps reroll boards that also reroll a slightly pricier
-- carry (a 1-cost with a 2-cost, say) in one core. Tanks are always core.
--
-- Within the core, the main unit on each side holds the most full items, and
-- a second unit on that side with var('core_min_full_items') or more is its
-- secondary. The main core carry's cost sets the leveling pattern
-- (seed_leveling_patterns), so a capped board stays in its core's pattern.
-- Reroll boards are the exception. Their carries all aim for 3 stars, and
-- whichever gets there first takes the items, so a 1-cost reroll can end with
-- a 2-cost carry holding the most. When a cheaper core carry also reached 3
-- stars (costs up to var('reroll_max_cost')), its cost sets the pattern.
-- Before var('leveling_pattern_from_stage'), nearly every board itemizes
-- cheap units, so the pattern is undetermined.

{% set core_min_full_items = var('core_min_full_items', 2) %}

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

core_costs AS (
    SELECT
        match_id, puuid,
        MIN(cost) AS core_cost,
        MIN(IF(cost <= {{ var('reroll_max_cost', 3) }} AND tier >= 3, cost, NULL)) AS reroll_cost
    FROM itemized_units
    WHERE side = 'carry' AND full_items >= {{ core_min_full_items }}
    GROUP BY match_id, puuid
),

slotted_units AS (
    SELECT
        itemized_units.*,
        CASE
            WHEN itemized_units.side = 'carry'
                AND itemized_units.full_items >= {{ core_min_full_items }}
                AND itemized_units.cost > core_costs.core_cost
                AND itemized_units.cost >= {{ var('cap_min_cost', 4) }}
            THEN 'cap'
            ELSE itemized_units.side
        END AS slot
    FROM            itemized_units
        LEFT JOIN   core_costs USING (match_id, puuid)
),

ranked AS (
    SELECT
        match_id, puuid, slot,
        ARRAY_AGG(
            STRUCT(character_id, cost, tier, full_items)
            ORDER BY full_items DESC, tier DESC, cost DESC, character_id
            LIMIT 2
        ) AS top_units
    FROM slotted_units
    GROUP BY match_id, puuid, slot
),

core_units AS (
    SELECT
        match_id, puuid,
        ARRAY_AGG(character_id ORDER BY character_id) AS core_character_ids
    FROM slotted_units
    WHERE slot != 'cap' AND full_items >= {{ core_min_full_items }}
    GROUP BY match_id, puuid
),

carries AS (SELECT match_id, puuid, top_units FROM ranked WHERE slot = 'carry'),
tanks AS (SELECT match_id, puuid, top_units FROM ranked WHERE slot = 'tank'),
caps AS (SELECT match_id, puuid, top_units FROM ranked WHERE slot = 'cap')

SELECT
    boards.match_id,
    boards.puuid,
    boards.tft_set_number,
    {% for side in ['carry', 'tank'] %}
    {{ side }}_units.top_units[SAFE_OFFSET(0)].character_id AS main_{{ side }}_character_id,
    {{ side }}_units.top_units[SAFE_OFFSET(0)].cost AS main_{{ side }}_cost,
    {{ side }}_units.top_units[SAFE_OFFSET(0)].tier AS main_{{ side }}_tier,
    {{ side }}_units.top_units[SAFE_OFFSET(0)].full_items AS main_{{ side }}_full_items,
    IF({{ side }}_units.top_units[SAFE_OFFSET(1)].full_items >= {{ core_min_full_items }},
        {{ side }}_units.top_units[SAFE_OFFSET(1)].character_id, NULL) AS secondary_{{ side }}_character_id,
    IF({{ side }}_units.top_units[SAFE_OFFSET(1)].full_items >= {{ core_min_full_items }},
        {{ side }}_units.top_units[SAFE_OFFSET(1)].full_items, NULL) AS secondary_{{ side }}_full_items,
    {% endfor %}
    IFNULL(core_units.core_character_ids, []) AS core_character_ids,
    ARRAY_TO_STRING(IFNULL(core_units.core_character_ids, []), ' + ') AS core_set,
    cap_units.top_units[SAFE_OFFSET(0)].character_id AS cap_character_id,
    cap_units.top_units[SAFE_OFFSET(0)].cost AS cap_cost,
    cap_units.top_units[SAFE_OFFSET(0)].tier AS cap_tier,
    cap_units.top_units[SAFE_OFFSET(0)].full_items AS cap_full_items,
    CASE
        WHEN schedule.stage < {{ var('leveling_pattern_from_stage', 4) }} THEN 'undetermined'
        WHEN carry_units.top_units IS NULL THEN 'no_carry'
        ELSE IFNULL(patterns.leveling_pattern, 'unclassified')
    END AS leveling_pattern
FROM            {{ ref('seed_annotated_boards') }} AS boards
    LEFT JOIN   carries AS carry_units USING (match_id, puuid)
    LEFT JOIN   tanks AS tank_units USING (match_id, puuid)
    LEFT JOIN   caps AS cap_units USING (match_id, puuid)
    LEFT JOIN   core_units USING (match_id, puuid)
    LEFT JOIN   core_costs USING (match_id, puuid)
    LEFT JOIN   {{ ref('seed_round_schedule') }} AS schedule
        ON schedule.set_num = boards.tft_set_number
        AND schedule.round_num = boards.last_round
    LEFT JOIN   {{ ref('seed_leveling_patterns') }} AS patterns
        ON patterns.set_num = boards.tft_set_number
        AND patterns.carry_cost = LEAST(
            carry_units.top_units[SAFE_OFFSET(0)].cost,
            IFNULL(core_costs.reroll_cost, carry_units.top_units[SAFE_OFFSET(0)].cost)
        )
