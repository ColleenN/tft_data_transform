SELECT 
    match_id, puuid, character_id, tier, unit_instance_index,
    cost, role, shop_unit,
    CAST(cost*POWER(3, tier-1) AS INT64) AS total_unit_cost
FROM
                {{ ref('unpacked_unified') }}
    LEFT JOIN 	{{ ref('seed_units') }}
        ON character_id = api_name
GROUP BY
    match_id, puuid, character_id, tier, unit_instance_index,
    cost, role, shop_unit