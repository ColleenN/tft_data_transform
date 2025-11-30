SELECT 
    match_id, puuid, character_id, tier, unit_instance_index,
    cost AS rarity, 
    CASE 
        WHEN character_id IN ('TFT16_AURELIONSOL', 'TFT16_BROCK', 'TFT16_SYLAS', 'TFT16_RYZE', 'TFT16_BARONNASHOR', 'TFT16_ZAAHEN') THEN 7
        ELSE cost
    END AS shop_gold_cost,
    role, shop_unit,
    CASE 
        WHEN character_id IN ('TFT16_AURELIONSOL', 'TFT16_BROCK', 'TFT16_SYLAS', 'TFT16_RYZE', 'TFT16_BARONNASHOR', 'TFT16_ZAAHEN') THEN CAST(7*POWER(3, tier-1) AS INT64)
        WHEN shop_unit = True THEN CAST(cost*POWER(3, tier-1) AS INT64)
        ELSE 0
    END AS total_unit_cost

FROM
                {{ ref('unpacked_unified') }}
    LEFT JOIN 	{{ ref('seed_units') }}
        ON character_id = api_name
GROUP BY
    match_id, puuid, character_id, tier, unit_instance_index,
    cost, role, shop_unit
