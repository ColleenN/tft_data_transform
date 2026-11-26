-- Each elimination round is compared with a baseline round. PvE rounds are
-- compared with the round before them, since players eliminated there mostly
-- stopped playing earlier (conceding, or going AFK before conceding is
-- allowed). Rounds with too few boards (carousels, the earliest rounds) then
-- borrow the baseline of the next round that has enough, or the last one
-- before them when none follows. AFK-suspected boards don't count toward a
-- round's boards.

{% set min_boards_by_channel = var('baseline_min_boards', {'pbe': 200, 'live': 500}) %}
{% set min_boards %}
    CASE channel
    {% for channel, boards in min_boards_by_channel.items() %}
        WHEN '{{ channel }}' THEN {{ boards }}
    {% endfor %}
        ELSE {{ min_boards_by_channel.get('live', 500) }}
    END
{% endset %}

WITH boards AS (
    SELECT DISTINCT
        resources.match_id, resources.puuid,
        resources.tft_set_number, resources.channel, resources.patch, resources.last_round,
        resources.afk_suspected,
        IF(schedule.round_type = 'pve', resources.last_round - 1, resources.last_round) AS comparison_round
    FROM            {{ ref('board_resources') }} AS resources
        LEFT JOIN   {{ ref('seed_round_schedule') }} AS schedule
            ON schedule.set_num = resources.tft_set_number
            AND schedule.round_num = resources.last_round
),

round_counts AS (
    SELECT
        tft_set_number, channel, patch, comparison_round,
        COUNTIF(NOT afk_suspected) AS num_boards,
        {{ min_boards | trim }} AS min_boards
    FROM boards
    GROUP BY tft_set_number, channel, patch, comparison_round
),

comparison_baselines AS (
    SELECT
        tft_set_number, channel, patch, comparison_round, num_boards,
        COALESCE(
            MIN(IF(num_boards >= min_boards, comparison_round, NULL)) OVER (
                PARTITION BY tft_set_number, channel, patch
                ORDER BY comparison_round
                ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
            ),
            MAX(IF(num_boards >= min_boards, comparison_round, NULL)) OVER (
                PARTITION BY tft_set_number, channel, patch
                ORDER BY comparison_round
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            comparison_round
        ) AS baseline_round
    FROM round_counts
)

SELECT DISTINCT
    boards.tft_set_number, boards.channel, boards.patch, boards.last_round,
    boards.comparison_round, comparison_baselines.num_boards, comparison_baselines.baseline_round
FROM            boards
    INNER JOIN  comparison_baselines
        USING (tft_set_number, channel, patch, comparison_round)
