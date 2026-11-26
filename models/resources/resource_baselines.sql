SELECT
    resources.tft_set_number,
    resources.channel,
    resources.patch,
    rounds.baseline_round,
    schedule.round_label AS baseline_round_label,
    resources.resource,
    AVG(resources.value) AS baseline_mean,
    STDDEV_SAMP(resources.value) AS baseline_stddev,
    COUNT(resources.value) AS baseline_boards
FROM            {{ ref('board_resources') }} AS resources
    INNER JOIN  {{ ref('baseline_rounds') }} AS rounds
        USING (tft_set_number, channel, patch, last_round)
    LEFT JOIN   {{ ref('seed_round_schedule') }} AS schedule
        ON schedule.set_num = resources.tft_set_number
        AND schedule.round_num = rounds.baseline_round
GROUP BY
    resources.tft_set_number, resources.channel, resources.patch,
    rounds.baseline_round, schedule.round_label, resources.resource
