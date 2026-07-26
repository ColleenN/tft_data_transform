SELECT 
    last_round,
    AVG(placement) AS avg_placement,

    AVG(annotated.level) AS avg_level,
    AVG(annotated.gold_left) AS avg_gold_left,
    AVG(annotated.cumulative_level_cost) AS avg_cumulative_level_cost,
    AVG(num_unit_slots) AS avg_num_unit_slots,
    AVG(num_units) AS avg_num_units,
    AVG(total_board_unit_cost) AS avg_total_board_unit_cost,
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


FROM {{ ref('seed_annotated_boards') }} AS annotated
JOIN {{ ref('aggregations_boards') }} AS aggregations USING (match_id, puuid)

GROUP BY last_round