SELECT
    resources.match_id,
    resources.puuid,
    resources.tft_set_number,
    resources.channel,
    resources.patch,
    resources.last_round,
    rounds.baseline_round,
    baselines.baseline_round_label,
    resources.resource,
    resources.value,
    baselines.baseline_mean,
    baselines.baseline_stddev,
    baselines.baseline_boards,
    SAFE_DIVIDE(resources.value - baselines.baseline_mean, baselines.baseline_stddev) AS z_score
FROM            {{ ref('board_resources') }} AS resources
    INNER JOIN  {{ ref('baseline_rounds') }} AS rounds
        USING (tft_set_number, channel, patch, last_round)
    INNER JOIN  {{ ref('resource_baselines') }} AS baselines
        ON baselines.tft_set_number = resources.tft_set_number
        AND baselines.channel = resources.channel
        AND baselines.patch = resources.patch
        AND baselines.baseline_round = rounds.baseline_round
        AND baselines.resource = resources.resource
