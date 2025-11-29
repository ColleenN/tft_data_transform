SELECT 
    match_id, puuid, character_id, tier, unit_instance_index,
    cost, role, shop_unit,
    CASE 
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