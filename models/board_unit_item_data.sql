SELECT
	match_id,
	puuid,
	character_id,
	jsonb_array_elements_text(item_json)
FROM dbt.board_unit_data