-- Set 14: boards with Viego that list more units than they can hold.
--
-- Viego's ability left "ghost" copies of units in the match payload. A board
-- with Viego and more units than its level plus Tactician's Crown slots allow
-- has at least one ghost. Ported from
-- postgres_archive/match_detail/viego_ghosts/ghost_board_known.sql.

WITH set14_boards AS (
    SELECT match_id, puuid, level
    FROM {{ ref('seed_annotated_boards') }}
    WHERE tft_set_number = 14
),

board_units AS (
    SELECT DISTINCT match_id, puuid, character_id, tier, unit_instance_index, raw_unit_rarity
    FROM {{ ref('unpacked_unified') }}
    WHERE tft_set_number = 14 AND character_id IS NOT NULL
),

unit_counts AS (
    SELECT
        match_id, puuid,
        COUNTIF(raw_unit_rarity < 7 AND NOT STARTS_WITH(character_id, 'TFT14_SUMMON')) AS num_units,
        LOGICAL_OR(character_id = 'TFT14_VIEGO') AS has_viego
    FROM board_units
    GROUP BY match_id, puuid
),

tac_items AS (
    SELECT match_id, puuid, SUM(IFNULL(num_tac_items, 0)) AS num_tac_items
    FROM {{ ref('seed_annotated_unified') }}
    WHERE tft_set_number = 14
    GROUP BY match_id, puuid
)

SELECT boards.match_id, boards.puuid
FROM            set14_boards AS boards
    INNER JOIN  unit_counts USING (match_id, puuid)
    LEFT JOIN   tac_items USING (match_id, puuid)
WHERE has_viego
    AND num_units - boards.level - IFNULL(num_tac_items, 0) > 0
