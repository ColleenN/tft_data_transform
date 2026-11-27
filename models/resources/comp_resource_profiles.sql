WITH boards AS (
    SELECT
        z.tft_set_number, z.channel, z.patch, schedule.stage,
        carries.leveling_pattern, carries.carry_character_id,
        z.resource, z.z_score
    FROM            {{ ref('board_resource_z_scores') }} AS z
        INNER JOIN  {{ ref('board_carries') }} AS carries USING (match_id, puuid)
        LEFT JOIN   {{ ref('seed_round_schedule') }} AS schedule
            ON schedule.set_num = z.tft_set_number
            AND schedule.round_num = z.baseline_round
    WHERE NOT z.afk_suspected AND z.z_score IS NOT NULL
),

grouped AS (
    SELECT *, 'leveling_pattern' AS group_level, leveling_pattern AS group_key
    FROM boards
    UNION ALL
    SELECT *, 'carry' AS group_level, carry_character_id AS group_key
    FROM boards
    WHERE carry_character_id IS NOT NULL
)

SELECT
    tft_set_number, channel, patch, group_level, group_key, leveling_pattern, stage, resource,
    COUNT(*) AS num_boards,
    AVG(z_score) AS mean_z_score,
    STDDEV_SAMP(z_score) AS stddev_z_score,
    SAFE_DIVIDE(STDDEV_SAMP(z_score), SQRT(COUNT(*))) AS standard_error
FROM grouped
GROUP BY tft_set_number, channel, patch, group_level, group_key, leveling_pattern, stage, resource
