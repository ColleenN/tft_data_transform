{{
    config(
        materialized='incremental'
    )
}}

WITH initial AS
(
	SELECT
		match_id,
		puuid,
		character_id,
		tier,
		bool_or(tg_item) OVER (
			PARTITION BY match_id,
			puuid,
			character_id,
			tier, unit_instance_index
		)
		AS has_generated_items,
		unit_instance_index,
		item_instance_index,
		seed_items.*
	FROM
				    {{ ref('board_unit_item_data') }}
	    LEFT JOIN 	{{ ref('seed_items') }}
		    ON item_api_name = api_name
	WHERE name IS NOT NULL
)
SELECT *
FROM initial
WHERE
    has_generated_items = False
   OR (has_generated_items = True AND tg_item = True)
