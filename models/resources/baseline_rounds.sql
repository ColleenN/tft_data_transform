-- Rounds with too few eliminations for a stable baseline (carousel and PvE
-- rounds, where almost nobody dies, and the earliest rounds) borrow the
-- baseline of the next round that has enough. Rounds past the last such round
-- borrow the one before them instead.

{% set min_boards = var('baseline_min_boards', 500) %}

WITH round_counts AS (
    SELECT
        tft_set_number, channel, patch, last_round,
        COUNT(DISTINCT FORMAT('%s|%s', match_id, puuid)) AS num_boards
    FROM {{ ref('board_resources') }}
    GROUP BY tft_set_number, channel, patch, last_round
)

SELECT
    tft_set_number, channel, patch, last_round, num_boards,
    COALESCE(
        MIN(IF(num_boards >= {{ min_boards }}, last_round, NULL)) OVER (
            PARTITION BY tft_set_number, channel, patch
            ORDER BY last_round
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ),
        MAX(IF(num_boards >= {{ min_boards }}, last_round, NULL)) OVER (
            PARTITION BY tft_set_number, channel, patch
            ORDER BY last_round
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        last_round
    ) AS baseline_round
FROM round_counts
