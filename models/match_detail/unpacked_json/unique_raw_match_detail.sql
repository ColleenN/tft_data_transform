{{
    config(
        materialized='incremental',
        unique_key='match_id'
    )
}}

WITH all_tables AS
(
	SELECT metadata->>'match_id' as match_id, metadata, info,
    'tft_player_match_detail' AS src_table, _sdc_sequence AS singer_id
	FROM tap_riotapi.tft_player_match_detail
	UNION
	SELECT metadata->>'match_id' as match_id, metadata, info,
	    'apex_ranked_ladder_match_detail' AS src_table, _sdc_sequence AS singer_id
	FROM tap_riotapi.apex_ranked_ladder_match_detail
	UNION
	SELECT metadata->>'match_id' as match_id, metadata, info,
	    'normal_ranked_ladder_match_detail' AS src_table, _sdc_sequence AS singer_id
	FROM tap_riotapi.normal_ranked_ladder_match_detail
)

SELECT DISTINCT ON(match_id) match_id, metadata, info, src_table, singer_id FROM all_tables