SELECT match_id,
    AVG(level) AS avg_level,
    AVG(last_round) AS avg_last_round,
    AVG(overall_gold_value) AS avg_overall_gold_value

FROM            {{ ref('seed_annotated_boards') }}
    LEFT JOIN   {{ ref('aggregations_boards') }} 
    USING (match_id, puuid, level)

GROUP BY match_id