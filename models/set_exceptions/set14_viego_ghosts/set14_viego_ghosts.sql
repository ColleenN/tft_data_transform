-- Set 14 Viego ghosts, in the set-exception output contract.
--
-- Candidates come from trait counts; boards where trait counts point at no one
-- fall back to champions listed more than once. Of each candidate's copies, the
-- ghost is the one holding exactly one craftable item and no emblem. Ported
-- from postgres_archive/match_detail/viego_ghosts/ghost_unit_certain.sql.

WITH ghost_boards AS (
    SELECT match_id, puuid
    FROM {{ ref('set14_viego_ghost_boards') }}
),

trait_candidates AS (
    SELECT match_id, puuid, character_id
    FROM {{ ref('set14_viego_ghost_trait_candidates') }}
),

ambiguous_boards AS (
    SELECT ghost_boards.match_id, ghost_boards.puuid
    FROM ghost_boards
        LEFT JOIN (SELECT DISTINCT match_id, puuid FROM trait_candidates) AS resolved
            USING (match_id, puuid)
    WHERE resolved.match_id IS NULL
),

duplicate_candidates AS (
    SELECT units.match_id, units.puuid, units.character_id
    FROM (
        SELECT DISTINCT match_id, puuid, character_id, tier, unit_instance_index
        FROM {{ ref('unpacked_unified') }}
        WHERE character_id IS NOT NULL
    ) AS units
        INNER JOIN ambiguous_boards USING (match_id, puuid)
    GROUP BY units.match_id, units.puuid, units.character_id
    HAVING COUNT(*) > 1
),

candidates AS (
    SELECT * FROM trait_candidates
    UNION DISTINCT
    SELECT * FROM duplicate_candidates
),

unit_items AS (
    SELECT
        items.match_id, items.puuid, items.character_id, items.tier, items.unit_instance_index,
        SUM(IFNULL(items.num_craftables, 0)) AS num_craftables,
        SUM(IFNULL(items.num_emblems, 0)) AS num_emblems
    FROM            {{ ref('seed_annotated_unified') }} AS items
        INNER JOIN  ghost_boards USING (match_id, puuid)
    WHERE items.character_id IS NOT NULL
    GROUP BY items.match_id, items.puuid, items.character_id, items.tier, items.unit_instance_index
)

SELECT
    unit_items.match_id,
    unit_items.puuid,
    unit_items.character_id,
    unit_items.tier,
    unit_items.unit_instance_index,
    'exclude_from_board' AS adjustment,
    'set14_viego_ghost' AS reason
FROM            candidates
    INNER JOIN  unit_items USING (match_id, puuid, character_id)
WHERE unit_items.num_craftables = 1
    AND unit_items.num_emblems = 0
