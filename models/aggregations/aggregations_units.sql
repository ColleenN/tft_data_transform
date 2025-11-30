SELECT  match_id, puuid, character_id, tier, unit_instance_index,
        shop_unit, rarity, total_unit_cost,
        CASE WHEN num_tg_items IS NULL THEN 0 ELSE num_tg_items END AS tg_item,
        COUNT(item_api_name) AS num_items,
        {{ select_item_category_sums() }},
        {{ select_item_component_sums() }}
FROM {{ ref('seed_annotated_unified') }}
GROUP BY    match_id, puuid, 
            character_id, tier, unit_instance_index,
            shop_unit, rarity, total_unit_cost, 
            num_tg_items