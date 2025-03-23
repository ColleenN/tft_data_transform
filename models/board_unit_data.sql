SELECT
	match_id,
	puuid,
	jsonb_array_elements(unit_list)->>'character_id' as character_id,
	jsonb_array_elements(unit_list)->>'tier' as tier,
	jsonb_array_elements(unit_list)->>'rarity' as unit_cost,
	jsonb_array_elements(unit_list)->'itemNames' as item_json,
	jsonb_array_elements(unit_list) as raw_unit_json
FROM dbt.base_board_data