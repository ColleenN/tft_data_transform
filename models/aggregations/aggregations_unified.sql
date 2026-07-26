SELECT
    -- unit identity
    units.match_id,
    units.puuid,
    units.character_id,
    units.tier,
    units.unit_instance_index,
    units.shop_unit,
    units.rarity,
    units.total_unit_cost,
    units.tg_item,

    -- unit-level item aggregates
    units.num_items            AS unit_num_items,
    units.num_craftables       AS unit_num_craftables,
    units.num_artifacts        AS unit_num_artifacts,
    units.num_radiants         AS unit_num_radiants,
    units.num_supports         AS unit_num_supports,
    units.num_emblems          AS unit_num_emblems,
    units.num_tac_items        AS unit_num_tac_items,
    units.num_swords           AS unit_num_swords,
    units.num_rods             AS unit_num_rods,
    units.num_bows             AS unit_num_bows,
    units.num_gloves           AS unit_num_gloves,
    units.num_tears            AS unit_num_tears,
    units.num_vests            AS unit_num_vests,
    units.num_cloaks           AS unit_num_cloaks,
    units.num_belts            AS unit_num_belts,
    units.num_spats            AS unit_num_spats,
    units.num_pans             AS unit_num_pans,

    -- board snapshot (player state at this level)
    annotated.placement,
    annotated.level,
    annotated.gold_left,
    annotated.last_round,
    annotated.players_eliminated,
    annotated.cumulative_level_cost,

    -- board-level aggregates
    boards.num_unit_slots,
    boards.num_units,
    boards.total_board_unit_cost,
    boards.overall_gold_value,
    boards.num_items           AS board_num_items,
    boards.num_craftables       AS board_num_craftables,
    boards.num_artifacts        AS board_num_artifacts,
    boards.num_radiants         AS board_num_radiants,
    boards.num_supports         AS board_num_supports,
    boards.num_emblems          AS board_num_emblems,
    boards.num_tac_items        AS board_num_tac_items,
    boards.num_swords           AS board_num_swords,
    boards.num_rods             AS board_num_rods,
    boards.num_bows             AS board_num_bows,
    boards.num_gloves           AS board_num_gloves,
    boards.num_tears            AS board_num_tears,
    boards.num_vests            AS board_num_vests,
    boards.num_cloaks           AS board_num_cloaks,
    boards.num_belts            AS board_num_belts,
    boards.num_spats            AS board_num_spats,
    boards.num_pans             AS board_num_pans,

    -- lobby (match-level) averages
    lobbies.avg_level          AS lobby_avg_level,
    lobbies.avg_last_round     AS lobby_avg_last_round,
    lobbies.avg_overall_gold_value AS lobby_avg_overall_gold_value,

    -- round-bucket (all matches ending on this round) averages
    end_round.avg_placement            AS round_avg_placement,
    end_round.avg_level                AS round_avg_level,
    end_round.avg_gold_left            AS round_avg_gold_left,
    end_round.avg_cumulative_level_cost AS round_avg_cumulative_level_cost,
    end_round.avg_num_unit_slots       AS round_avg_num_unit_slots,
    end_round.avg_num_units            AS round_avg_num_units,
    end_round.avg_total_board_unit_cost AS round_avg_total_board_unit_cost,
    end_round.avg_overall_gold_value   AS round_avg_overall_gold_value,
    end_round.avg_num_items            AS round_avg_num_items,
    end_round.avg_num_craftables       AS round_avg_num_craftables,
    end_round.avg_num_artifacts        AS round_avg_num_artifacts,
    end_round.avg_num_radiants         AS round_avg_num_radiants,
    end_round.avg_num_supports         AS round_avg_num_supports,
    end_round.avg_num_emblems          AS round_avg_num_emblems,
    end_round.avg_num_swords           AS round_avg_num_swords,
    end_round.avg_num_rods             AS round_avg_num_rods,
    end_round.avg_num_bows             AS round_avg_num_bows,
    end_round.avg_num_gloves           AS round_avg_num_gloves,
    end_round.avg_num_tears            AS round_avg_num_tears,
    end_round.avg_num_vests            AS round_avg_num_vests,
    end_round.avg_num_cloaks           AS round_avg_num_cloaks,
    end_round.avg_num_belts            AS round_avg_num_belts,
    end_round.avg_num_spats            AS round_avg_num_spats,
    end_round.avg_num_pans             AS round_avg_num_pans

FROM            {{ ref('aggregations_units') }} AS units
    LEFT JOIN   {{ ref('seed_annotated_boards') }} AS annotated
        USING (match_id, puuid)
    LEFT JOIN   {{ ref('aggregations_boards') }} AS boards
        USING (match_id, puuid, level)
    LEFT JOIN   {{ ref('aggregations_lobbies') }} AS lobbies
        USING (match_id)
    LEFT JOIN   {{ ref('aggregations_end_round') }} AS end_round
        USING (last_round)
