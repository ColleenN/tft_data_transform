WITH initial AS
(
	SELECT
		match_id,
		puuid,
		character_id,
		tier,
		CASE WHEN SUM(num_tg_items
		) OVER (
			PARTITION BY match_id,
			puuid,
			character_id,
			tier, unit_instance_index
		) > 0 THEN True ELSE False END
		AS has_generated_items,
		unit_instance_index,
		item_instance_index,
		seed_items.*
	FROM
				    {{ ref('unpacked_unified') }}
	    LEFT JOIN 	{{ ref('seed_items') }} USING (item_api_name)
	WHERE item_api_name IS NOT NULL
)

SELECT *
FROM initial
WHERE
    has_generated_items = False
    OR (has_generated_items = True AND num_tg_items = 1)