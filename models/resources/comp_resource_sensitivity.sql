-- Every board is paired with each lobbymate, from its own side: z_lead is
-- how far ahead of that lobbymate it was on a resource (each measured against
-- its own baseline round), and placed_better whether it finished ahead.
-- Boards are recorded when eliminated, so lobbymates' resources come from
-- different points in the game; how much of the outcome the leads explain is
-- part of what this measures.

WITH boards AS (
    SELECT
        z.match_id, z.puuid, z.tft_set_number, z.channel, z.patch, z.resource, z.z_score,
        boards.placement, carries.leveling_pattern, carries.carry_character_id
    FROM            {{ ref('board_resource_z_scores') }} AS z
        INNER JOIN  {{ ref('seed_annotated_boards') }} AS boards USING (match_id, puuid)
        INNER JOIN  {{ ref('board_carries') }} AS carries USING (match_id, puuid)
    WHERE NOT z.afk_suspected AND z.z_score IS NOT NULL
),

pairs AS (
    SELECT
        board.tft_set_number, board.channel, board.patch, board.resource,
        board.leveling_pattern, board.carry_character_id,
        board.z_score - lobbymate.z_score AS z_lead,
        IF(board.placement < lobbymate.placement, 1, 0) AS placed_better
    FROM            boards AS board
        INNER JOIN  boards AS lobbymate
            ON lobbymate.match_id = board.match_id
            AND lobbymate.resource = board.resource
            AND lobbymate.puuid != board.puuid
),

grouped AS (
    SELECT *, 'leveling_pattern' AS group_level, leveling_pattern AS group_key
    FROM pairs
    UNION ALL
    SELECT *, 'carry' AS group_level, carry_character_id AS group_key
    FROM pairs
    WHERE carry_character_id IS NOT NULL
)

SELECT
    tft_set_number, channel, patch, group_level, group_key, leveling_pattern, resource,
    COUNT(*) AS num_pairs,
    COUNTIF(z_lead > 0) AS num_pairs_ahead,
    AVG(placed_better) AS placed_better_rate,
    SAFE_DIVIDE(COUNTIF(z_lead > 0 AND placed_better = 1), COUNTIF(z_lead > 0)) AS placed_better_rate_when_ahead,
    SAFE_DIVIDE(COVAR_SAMP(placed_better, z_lead), VAR_SAMP(z_lead)) AS placed_better_per_z_lead,
    POW(CORR(placed_better, z_lead), 2) AS r_squared
FROM grouped
GROUP BY tft_set_number, channel, patch, group_level, group_key, leveling_pattern, resource
