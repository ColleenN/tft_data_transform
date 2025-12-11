SELECT  match_id, puuid, character_id, tier, unit_instance_index,
        CASE WHEN num_tg_items IS NULL THEN 0 ELSE num_tg_items END AS tg_item,
        {{ select_item_category_sums() }},
        {{ select_item_component_sums() }}
--FROM {{ ref('seed_annotated_units') }}
FROM {{ ref('seed_annotated_unified') }}
GROUP BY match_id, puuid, character_id, tier, unit_instance_index, num_tg_items. 
