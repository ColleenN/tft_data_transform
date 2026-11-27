WITH boards AS (
    SELECT
        boards.tft_set_number, builds.channel, builds.patch,
        carries.leveling_pattern, carries.carry_character_id,
        boards.placement, boards.last_round
    FROM            {{ ref('seed_annotated_boards') }} AS boards
        INNER JOIN  {{ ref('board_carries') }} AS carries USING (match_id, puuid)
        INNER JOIN  {{ ref('match_reference_snapshots') }} AS builds USING (match_id)
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
    tft_set_number, channel, patch, group_level, group_key, leveling_pattern,
    COUNT(*) AS num_boards,
    AVG(placement) AS avg_placement,
    STDDEV_SAMP(placement) AS stddev_placement,
    AVG(IF(placement <= 4, 1, 0)) AS top_4_rate,
    {% for place in range(1, 9) %}
    AVG(IF(placement = {{ place }}, 1, 0)) AS placement_{{ place }}_share,
    {% endfor %}
    AVG(last_round) AS avg_last_round
FROM grouped
GROUP BY tft_set_number, channel, patch, group_level, group_key, leveling_pattern
