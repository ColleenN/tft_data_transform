SELECT
	match_id,
	puuid,
	jsonb_array_elements(unit_list)->>'character_id' as character_id,
	(jsonb_array_elements(unit_list)->>'tier')::int as tier,
	jsonb_array_elements(unit_list)->>'raw_rarity' as unit_cost,
	jsonb_array_elements(unit_list)->'itemNames' as item_json,
	jsonb_array_elements(unit_list) as raw_unit_json
FROM {{ ref('base_board_data') }}