SELECT DISTINCT
    match_id, puuid, character_id, tier, unit_instance_index,
    units.cost AS rarity,
    units.shop_gold_cost,
    units.role,
    CASE
        WHEN character_id IS NULL THEN NULL
        ELSE IFNULL(units.shop_unit, FALSE)
    END AS shop_unit,
    CASE
        WHEN character_id IS NULL THEN NULL
        ELSE IFNULL(units.takes_board_slot, TRUE)
    END AS takes_board_slot,
    CASE
        WHEN character_id IS NULL THEN NULL
        ELSE CAST(IFNULL(units.one_star_gold_value, 0) * POWER(3, tier - 1) AS INT64)
    END AS total_unit_cost

FROM
                {{ ref('unpacked_unified') }} AS unpacked
    LEFT JOIN   {{ ref('set_units') }} AS units
        ON unpacked.character_id = units.api_name
