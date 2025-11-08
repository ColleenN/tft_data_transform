SELECT 	units.match_id, units.puuid, units.character_id, units.tier, units.unit_instance_index,
		CASE WHEN items.num_tg_items IS NULL THEN 0 ELSE items.num_tg_items END AS tg_item,
        {{ select_item_category_sums() }},
        {{ select_item_component_sums() }}
FROM
        {{ ref('board_unit_data') }} units
		{{ join_on_board_id('units', ref('annotated_unit_item_entries'), 'items') }}
        AND units.character_id = items.character_id
        AND units.tier = items.tier
        AND units.unit_instance_index = items.unit_instance_index
GROUP BY units.match_id,
         units.puuid,
         units.character_id,
         units.tier,
         units.unit_instance_index,
         items.num_tg_items