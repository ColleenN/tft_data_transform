{{
    config(
        materialized='incremental',
        unique_key='match_id'
    )
}}

WITH all_tables AS
(
    SELECT 
        JSON_VALUE(data, "$.metadata.match_id") AS match_id,
        JSON_QUERY(data, "$.metadata") AS metadata,
        JSON_QUERY(data, "$.info") AS info,
        JSON_VALUE(data, "$.info.queue_id") AS queue_id,
        CAST(TIMESTAMP_MILLIS(CAST(JSON_VALUE(data, "$.info.gameCreation") AS INT64)) AS DATETIME) AS server_side_game_start,
        REGEXP_EXTRACT(JSON_VALUE(data, "$.info.game_version"), r'[^\(]*?\(([^\)]*?)\)') AS last_client_update_datetime,
        REGEXP_EXTRACT(JSON_VALUE(data, "$.info.game_version"), r'Linux Version (.*?) \(' ) AS game_client_version_id,
        CAST(JSON_VALUE(data, "$.info.tft_set_number") AS INT64) AS tft_set_number,
	    'normal_ranked_ladder_match_detail' AS src_table, _sdc_sequence AS singer_id,
	FROM match_data_landing_zone.normal_ranked_ladder_match_detail
    UNION ALL
	SELECT 
        JSON_VALUE(data, "$.metadata.match_id") AS match_id,
        JSON_QUERY(data, "$.metadata") AS metadata,
        JSON_QUERY(data, "$.info") AS info,
        JSON_VALUE(data, "$.info.queue_id") AS queue_id,
        CAST(TIMESTAMP_MILLIS(CAST(JSON_VALUE(data, "$.info.gameCreation") AS INT64)) AS DATETIME) AS server_side_game_start,
        REGEXP_EXTRACT(JSON_VALUE(data, "$.info.game_version"), r'[^\(]*?\(([^\)]*?)\)') AS last_client_update_datetime,
        REGEXP_EXTRACT(JSON_VALUE(data, "$.info.game_version"), r'Linux Version (.*?) \(' ) AS game_client_version_id,
        CAST(JSON_VALUE(data, "$.info.tft_set_number") AS INT64) AS tft_set_number,
	    'apex_ranked_ladder_match_detail' AS src_table, _sdc_sequence AS singer_id,
	FROM match_data_landing_zone.apex_ranked_ladder_match_detail
    UNION ALL
    SELECT
        JSON_VALUE(data, "$.metadata.match_id") AS match_id,
        JSON_QUERY(data, "$.metadata") AS metadata,
        JSON_QUERY(data, "$.info") AS info,
        JSON_VALUE(data, "$.info.queue_id") AS queue_id,
        CAST(TIMESTAMP_MILLIS(CAST(JSON_VALUE(data, "$.info.gameCreation") AS INT64)) AS DATETIME) AS server_side_game_start,
        REGEXP_EXTRACT(JSON_VALUE(data, "$.info.game_version"), r'[^\(]*?\(([^\)]*?)\)') AS last_client_update_datetime,
        REGEXP_EXTRACT(JSON_VALUE(data, "$.info.game_version"), r'Linux Version (.*?) \(' ) AS game_client_version_id,
        CAST(JSON_VALUE(data, "$.info.tft_set_number") AS INT64) AS tft_set_number,
        'tft_player_match_detail' AS src_table, _sdc_sequence AS singer_id,
	FROM match_data_landing_zone.tft_player_match_detail
)

SELECT  match_id, SPLIT(match_id, '_')[0] AS server_realm_code, queue_id, server_side_game_start, tft_set_number,
        metadata, info, src_table, singer_id, last_client_update_datetime, 
        game_client_version_id,
ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY singer_id DESC) AS instance
FROM all_tables
WHERE ((SPLIT(match_id, '_')[0] = 'PBE1' and queue_id = '1090') OR (queue_id = '1100'))
    AND JSON_VALUE(info, "$.endOfGameResult") = "GameComplete"
    AND ARRAY_LENGTH(JSON_VALUE_ARRAY(metadata, "$.participants")) = 8
QUALIFY instance = 1