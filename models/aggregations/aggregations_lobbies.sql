SELECT match_id,
    AVG(level) AS avg_level,
    AVG(last_round) AS avg_last_round,
    AVG(overall_gold_value) AS avg_overall_gold_value,

    AVG(num_items) AS avg_num_items,
    AVG(num_craftables) AS avg_num_craftables,
    AVG(num_artifacts) AS avg_num_artifacts,
    AVG(num_radiants) AS avg_num_radiants,
    AVG(num_supports) AS avg_num_supports,
    AVG(num_emblems) AS avg_num_emblems,

    AVG(num_swords) AS avg_num_swords,
    AVG(num_rods) AS avg_num_rods,
    AVG(num_bows) AS avg_num_bows,
    AVG(num_gloves) AS avg_num_gloves,
    AVG(num_tears) AS avg_num_tears,
    AVG(num_vests) AS avg_num_vests,
    AVG(num_cloaks) AS avg_num_cloaks,
    AVG(num_belts) AS avg_num_belts,
    AVG(num_spats) AS avg_num_spats,
    AVG(num_pans) AS avg_num_pans

FROM            {{ ref('seed_annotated_boards') }}
    LEFT JOIN   {{ ref('aggregations_boards') }} 
    USING (match_id, puuid, level)

GROUP BY match_id