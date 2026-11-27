-- The core sets each family plays, per set, channel and patch. A board's core
-- set is its core units holding var('core_min_full_items') or more full items
-- (see board_cores); the family's most common set is its standard core, and
-- every other set is described by how it differs from it.

WITH boards AS (
    SELECT
        boards.tft_set_number, builds.channel, builds.patch, cores.leveling_pattern,
        FORMAT('%s + %s', cores.main_carry_character_id, IFNULL(cores.main_tank_character_id, 'no tank')) AS family,
        cores.core_set,
        IF(cores.core_set = '', [], SPLIT(cores.core_set, ' + ')) AS core_character_ids,
        cores.cap_character_id,
        boards.placement
    FROM            {{ ref('seed_annotated_boards') }} AS boards
        INNER JOIN  {{ ref('board_cores') }} AS cores USING (match_id, puuid)
        INNER JOIN  {{ ref('match_reference_snapshots') }} AS builds USING (match_id)
    WHERE cores.main_carry_character_id IS NOT NULL
        AND cores.leveling_pattern != 'undetermined'
),

core_sets AS (
    SELECT
        tft_set_number, channel, patch, leveling_pattern, family, core_set,
        ANY_VALUE(core_character_ids) AS core_character_ids,
        COUNT(*) AS num_boards,
        AVG(placement) AS avg_placement,
        AVG(IF(placement <= 4, 1, 0)) AS top_4_rate,
        AVG(IF(cap_character_id IS NOT NULL, 1, 0)) AS cap_rate
    FROM boards
    GROUP BY tft_set_number, channel, patch, leveling_pattern, family, core_set
),

ranked AS (
    SELECT
        *,
        num_boards / SUM(num_boards) OVER family_sets AS family_share,
        ROW_NUMBER() OVER (family_sets ORDER BY num_boards DESC, core_set) AS core_set_rank
    FROM core_sets
    WINDOW family_sets AS (PARTITION BY tft_set_number, channel, patch, leveling_pattern, family)
),

standard AS (
    SELECT tft_set_number, channel, patch, leveling_pattern, family, core_character_ids AS standard_character_ids
    FROM ranked
    WHERE core_set_rank = 1
),

compared AS (
    SELECT
        ranked.*,
        ARRAY(
            SELECT character_id FROM UNNEST(ranked.core_character_ids) AS character_id
            WHERE character_id NOT IN UNNEST(standard.standard_character_ids)
            ORDER BY character_id
        ) AS added_ids,
        ARRAY(
            SELECT character_id FROM UNNEST(standard.standard_character_ids) AS character_id
            WHERE character_id NOT IN UNNEST(ranked.core_character_ids)
            ORDER BY character_id
        ) AS dropped_ids
    FROM            ranked
        INNER JOIN  standard USING (tft_set_number, channel, patch, leveling_pattern, family)
)

SELECT
    tft_set_number, channel, patch, leveling_pattern, family, core_set, core_set_rank,
    CASE
        WHEN core_set_rank = 1 THEN 'standard'
        WHEN ARRAY_LENGTH(added_ids) = 1 AND ARRAY_LENGTH(dropped_ids) = 1 THEN 'swap'
        WHEN ARRAY_LENGTH(added_ids) = 1 AND ARRAY_LENGTH(dropped_ids) = 0 THEN 'extra'
        WHEN ARRAY_LENGTH(added_ids) = 0 AND ARRAY_LENGTH(dropped_ids) = 1 THEN 'missing'
        ELSE 'other'
    END AS variant_type,
    ARRAY_TO_STRING(added_ids, ' + ') AS units_added,
    ARRAY_TO_STRING(dropped_ids, ' + ') AS units_dropped,
    num_boards,
    family_share,
    avg_placement,
    top_4_rate,
    cap_rate
FROM compared
