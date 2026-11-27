-- A board's carry is the shop unit holding the most items, and the carry's
-- cost sets the leveling pattern (seed_leveling_patterns). The pattern comes
-- from cost alone, not star level, so reroll attempts that never hit their
-- 3-star stay in their pattern. Before var('leveling_pattern_from_stage'),
-- nearly every board itemizes cheap units, so the pattern is undetermined.

WITH unit_items AS (
    SELECT match_id, puuid, character_id, tier, unit_instance_index, COUNT(item_api_name) AS num_items
    FROM {{ ref('seed_annotated_unit_items') }}
    GROUP BY match_id, puuid, character_id, tier, unit_instance_index
),

itemized_units AS (
    SELECT units.match_id, units.puuid, units.character_id, units.tier, units.rarity, unit_items.num_items
    FROM            {{ ref('seed_annotated_units') }} AS units
        INNER JOIN  unit_items USING (match_id, puuid, character_id, tier, unit_instance_index)
    WHERE units.shop_unit AND unit_items.num_items > 0
),

carries AS (
    SELECT
        match_id, puuid,
        ARRAY_AGG(
            STRUCT(character_id, rarity AS cost, tier, num_items)
            ORDER BY num_items DESC, tier DESC, rarity DESC, character_id
            LIMIT 1
        )[OFFSET(0)] AS carry
    FROM itemized_units
    GROUP BY match_id, puuid
)

SELECT
    boards.match_id,
    boards.puuid,
    boards.tft_set_number,
    carries.carry.character_id AS carry_character_id,
    carries.carry.cost AS carry_cost,
    carries.carry.tier AS carry_tier,
    carries.carry.num_items AS carry_num_items,
    CASE
        WHEN carries.carry IS NULL THEN 'no_carry'
        WHEN schedule.stage < {{ var('leveling_pattern_from_stage', 4) }} THEN 'undetermined'
        ELSE IFNULL(patterns.leveling_pattern, 'unclassified')
    END AS leveling_pattern
FROM            {{ ref('seed_annotated_boards') }} AS boards
    LEFT JOIN   carries USING (match_id, puuid)
    LEFT JOIN   {{ ref('seed_round_schedule') }} AS schedule
        ON schedule.set_num = boards.tft_set_number
        AND schedule.round_num = boards.last_round
    LEFT JOIN   {{ ref('seed_leveling_patterns') }} AS patterns
        ON patterns.set_num = boards.tft_set_number
        AND patterns.carry_cost = carries.carry.cost
