-- Set 14: ghost candidates found by trait counts.
--
-- A ghost doesn't count toward traits, so on a ghost board some trait's
-- active unit count (from the API) is one lower than the count implied by the
-- listed units. The champions contributing to the most of those overcounted
-- traits are the likeliest ghosts. Ported from
-- postgres_archive/match_detail/viego_ghosts/ghost_possible_by_traits.sql and
-- the derived/ trait models it depended on.
--
-- Needs Set 14 rows in seed_unit_innate_traits; it finds nothing without them.

WITH ghost_boards AS (
    SELECT match_id, puuid
    FROM {{ ref('set14_viego_ghost_boards') }}
),

board_characters AS (
    SELECT DISTINCT units.match_id, units.puuid, units.character_id
    FROM            {{ ref('unpacked_unified') }} AS units
        INNER JOIN  ghost_boards USING (match_id, puuid)
    WHERE units.character_id IS NOT NULL
),

-- Traits counted per distinct champion, innate or from an emblem.
unit_traits AS (
    SELECT chars.match_id, chars.puuid, chars.character_id, UPPER(traits.trait_api_name) AS trait
    FROM            board_characters AS chars
        INNER JOIN  {{ ref('seed_unit_innate_traits') }} AS traits
            ON chars.character_id = UPPER(traits.api_name)
    UNION DISTINCT
    SELECT items.match_id, items.puuid, items.character_id, UPPER(items.trait_granted) AS trait
    FROM            {{ ref('seed_annotated_unified') }} AS items
        INNER JOIN  ghost_boards USING (match_id, puuid)
    WHERE items.trait_granted IS NOT NULL
),

overcounted_traits AS (
    SELECT counted.match_id, counted.puuid, counted.trait
    FROM (
        SELECT match_id, puuid, trait, COUNT(*) AS counted_units
        FROM unit_traits
        GROUP BY match_id, puuid, trait
    ) AS counted
        LEFT JOIN {{ ref('unpacked_traits') }} AS active
            ON active.match_id = counted.match_id
            AND active.puuid = counted.puuid
            AND active.name = counted.trait
    WHERE IFNULL(active.num_units, 0) - counted.counted_units = -1
),

ghost_scores AS (
    SELECT unit_traits.match_id, unit_traits.puuid, unit_traits.character_id, COUNT(*) AS ghost_score
    FROM            unit_traits
        INNER JOIN  overcounted_traits USING (match_id, puuid, trait)
    GROUP BY unit_traits.match_id, unit_traits.puuid, unit_traits.character_id
)

SELECT match_id, puuid, character_id
FROM ghost_scores
QUALIFY ghost_score = MAX(ghost_score) OVER (PARTITION BY match_id, puuid)
