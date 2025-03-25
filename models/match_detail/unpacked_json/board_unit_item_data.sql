SELECT
	match_id,
	puuid,
	character_id,
	tier,
	unit_instance_index,
	jsonb_array_elements_text(item_json) as item_api_name
FROM {{ ref('board_unit_data') }}