SELECT
	metadata->>'match_id' as match_id,
	jsonb_array_elements(info['participants'])->>'puuid' as puuid,
	(jsonb_array_elements(info['participants'])->>'placement')::int as placement,
	(jsonb_array_elements(info['participants'])->>'level')::int as level,
	(jsonb_array_elements(info['participants'])->>'gold_left')::int as gold_left,
	(left(jsonb_array_elements(info['participants'])->>'last_round', 1))::int as stage_eliminated,
	(right(jsonb_array_elements(info['participants'])->>'last_round', 1))::int as round_eliminated,
	(jsonb_array_elements(info['participants'])->>'time_eliminated')::decimal as time_eliminated,
	(jsonb_array_elements(info['participants'])->>'players_eliminated')::int as players_eliminated,
	(jsonb_array_elements(info['participants'])->>'total_damage_to_players')::int as total_damage_to_players,
	jsonb_array_elements(info['participants'])->'units' as unit_list,
	jsonb_array_elements(info['participants'])->'traits' as trait_list,
	jsonb_array_elements(info['participants']) as raw_board_record
FROM {{ ref('unique_raw_match_detail') }}
