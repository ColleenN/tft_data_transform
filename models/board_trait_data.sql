SELECT
	match_id,
	puuid,
	jsonb_array_elements(trait_list)->>'name' as name,
	(jsonb_array_elements(trait_list)->>'num_units')::int as num_units,
	(jsonb_array_elements(trait_list)->>'tier_current')::int as tier_current,
	jsonb_array_elements(trait_list) as raw_trait_json
FROM dbt.base_board_data