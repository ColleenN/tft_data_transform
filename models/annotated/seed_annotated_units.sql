SELECT DISTINCT
    unpacked.match_id, unpacked.puuid, unpacked.character_id, unpacked.tier, unpacked.unit_instance_index,
    units.cost AS rarity,
    units.shop_gold_cost,
    units.role,
    CASE
        WHEN character_id IS NULL THEN NULL
        ELSE IFNULL(units.shop_unit, FALSE)
    END AS shop_unit,
    CASE
        WHEN character_id IS NULL THEN NULL
        ELSE IFNULL(units.num_board_slots, 1)
    END AS num_board_slots,
    CASE
        WHEN character_id IS NULL THEN NULL
        ELSE CAST(IFNULL(units.one_star_gold_value, 0) * POWER(3, tier - 1) AS INT64)
    END AS total_unit_cost

FROM
                {{ ref('unpacked_unified') }} AS unpacked
    LEFT JOIN   {{ ref('match_reference_snapshots') }} AS builds USING (match_id)
    LEFT JOIN   {{ ref('set_units') }} AS units
        ON units.source_object = builds.reference_source_object
        AND units.set_num = unpacked.tft_set_number
        AND units.api_name = unpacked.character_id
