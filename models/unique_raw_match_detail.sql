WITH all_tables AS
(
	SELECT metadata->>'match_id' as match_id, metadata, info
	FROM tap_riotapi.tft_player_match_detail
	UNION
	SELECT metadata->>'match_id' as match_id, metadata, info
	FROM tap_riotapi.apex_ranked_ladder_match_detail
	UNION
	SELECT metadata->>'match_id' as match_id, metadata, info
	FROM tap_riotapi.normal_ranked_ladder_match_detail
)

SELECT DISTINCT ON(match_id) metadata, info FROM all_tables