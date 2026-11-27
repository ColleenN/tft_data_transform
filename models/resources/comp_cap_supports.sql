-- Which units come along with each cap. A cap is a carry that stands alone or
-- brings a supporting unit, usually one sharing a trait with it. For every
-- family, cap and unit outside the core, this compares how often the unit is
-- on boards with that cap against how often it's on the family's other
-- boards at the same level, since higher levels field more units of every
-- kind. A support shares a trait with the cap, shows up on at least
-- var('cap_support_min_rate') of its boards, and does so at least
-- var('cap_support_min_lift') more often than expected.

WITH boards AS (
    SELECT
        boards.match_id, boards.puuid, boards.tft_set_number, builds.channel, builds.patch,
        cores.leveling_pattern,
        FORMAT('%s + %s', cores.main_carry_character_id, IFNULL(cores.main_tank_character_id, 'no tank')) AS family,
        cores.core_set, cores.cap_character_id, boards.level
    FROM            {{ ref('seed_annotated_boards') }} AS boards
        INNER JOIN  {{ ref('board_cores') }} AS cores USING (match_id, puuid)
        INNER JOIN  {{ ref('match_reference_snapshots') }} AS builds USING (match_id)
    WHERE cores.main_carry_character_id IS NOT NULL
        AND cores.leveling_pattern != 'undetermined'
),

flex_units AS (
    SELECT DISTINCT boards.*, units.character_id
    FROM            boards
        INNER JOIN  {{ ref('seed_annotated_units') }} AS units USING (match_id, puuid)
    WHERE units.shop_unit
        AND units.character_id NOT IN UNNEST(SPLIT(boards.core_set, ' + '))
        AND units.character_id != IFNULL(boards.cap_character_id, '')
),

level_boards AS (
    SELECT tft_set_number, channel, patch, leveling_pattern, family, level, COUNT(*) AS num_boards
    FROM boards
    GROUP BY tft_set_number, channel, patch, leveling_pattern, family, level
),

level_units AS (
    SELECT tft_set_number, channel, patch, leveling_pattern, family, level, character_id, COUNT(*) AS num_boards
    FROM flex_units
    GROUP BY tft_set_number, channel, patch, leveling_pattern, family, level, character_id
),

cap_level_boards AS (
    SELECT tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, level, COUNT(*) AS num_boards
    FROM boards
    WHERE cap_character_id IS NOT NULL
    GROUP BY tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, level
),

cap_level_units AS (
    SELECT tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, level, character_id, COUNT(*) AS num_boards
    FROM flex_units
    WHERE cap_character_id IS NOT NULL
    GROUP BY tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, level, character_id
),

candidates AS (
    SELECT DISTINCT tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, character_id
    FROM cap_level_units
),

-- every level a cap was seen at, for every unit seen with it, compared with
-- the family's boards at that level that didn't have the cap
by_level AS (
    SELECT
        candidates.*,
        cap_level_boards.num_boards AS capped_boards,
        IFNULL(cap_level_units.num_boards, 0) AS capped_boards_with_unit,
        level_boards.num_boards - cap_level_boards.num_boards AS other_boards,
        IFNULL(level_units.num_boards, 0) - IFNULL(cap_level_units.num_boards, 0) AS other_boards_with_unit
    FROM            candidates
        INNER JOIN  cap_level_boards USING (tft_set_number, channel, patch, leveling_pattern, family, cap_character_id)
        LEFT JOIN   cap_level_units USING (tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, level, character_id)
        INNER JOIN  level_boards USING (tft_set_number, channel, patch, leveling_pattern, family, level)
        LEFT JOIN   level_units USING (tft_set_number, channel, patch, leveling_pattern, family, level, character_id)
    WHERE level_boards.num_boards > cap_level_boards.num_boards
),

rates AS (
    SELECT
        tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, character_id,
        SUM(capped_boards) AS num_capped_boards,
        SUM(capped_boards_with_unit) / SUM(capped_boards) AS rate_with_cap,
        SUM(capped_boards * other_boards_with_unit / other_boards) / SUM(capped_boards) AS expected_rate
    FROM by_level
    GROUP BY tft_set_number, channel, patch, leveling_pattern, family, cap_character_id, character_id
),

shared_traits AS (
    SELECT DISTINCT cap_traits.set_num, cap_traits.api_name AS cap_character_id, unit_traits.api_name AS character_id
    FROM            {{ ref('set_unit_traits') }} AS cap_traits
        INNER JOIN  {{ ref('set_unit_traits') }} AS unit_traits USING (source_object, set_num, trait_api_name)
    WHERE cap_traits.api_name != unit_traits.api_name
        AND cap_traits.num_trait_units >= 2
)

SELECT
    rates.*,
    rates.rate_with_cap - rates.expected_rate AS lift,
    shared_traits.character_id IS NOT NULL AS shares_trait,
    shared_traits.character_id IS NOT NULL
        AND rates.rate_with_cap >= {{ var('cap_support_min_rate', 0.5) }}
        AND rates.rate_with_cap - rates.expected_rate >= {{ var('cap_support_min_lift', 0.25) }}
        AS is_support
FROM            rates
    LEFT JOIN   shared_traits
        ON shared_traits.set_num = rates.tft_set_number
        AND shared_traits.cap_character_id = rates.cap_character_id
        AND shared_traits.character_id = rates.character_id
