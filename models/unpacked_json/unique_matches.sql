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
	    'apex_ranked_ladder_match_detail' AS src_table, _sdc_sequence AS singer_id,
	FROM match_data_landing_zone.apex_ranked_ladder_match_detail
)

SELECT match_id, metadata, info, src_table, singer_id, ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY singer_id DESC) as instance
FROM all_tables
WHERE queue_id = "1100"
QUALIFY instance = 1
