{{
    config(
        materialized='incremental'
    )
}}

SELECT
	match_id,
	puuid,
	character_id,
	tier,
	unit_instance_index,
	item_instance_index,
	seed_items.*
FROM
				{{ ref('board_unit_item_data') }}
	LEFT JOIN 	{{ ref('seed_items') }}
		ON item_api_name = api_name
WHERE name IS NOT NULL