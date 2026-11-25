-- Match records sometimes name an item differently from the reference data
-- (seed_item_aliases), so items are matched and reported under the reference
-- name.
WITH resolved AS
(
	SELECT
		unpacked.* EXCEPT (item_api_name),
		COALESCE(aliases.item_api_name, unpacked.item_api_name) AS item_api_name
	FROM
				    {{ ref('unpacked_unified') }} AS unpacked
	    LEFT JOIN 	{{ ref('seed_item_aliases') }} AS aliases
	        ON aliases.set_num = unpacked.tft_set_number
	        AND aliases.match_item_api_name = unpacked.item_api_name
),

initial AS
(
	SELECT
		unpacked.match_id,
		unpacked.puuid,
		unpacked.character_id,
		unpacked.tier,
		CASE WHEN SUM(items.num_tg_items
		) OVER (
			PARTITION BY
			unpacked.match_id,
			unpacked.puuid,
			unpacked.character_id,
			unpacked.tier, unpacked.unit_instance_index
		) > 0 THEN True ELSE False END
		AS has_generated_items,
		unpacked.unit_instance_index,
		unpacked.item_instance_index,
		unpacked.item_api_name,
		items.* EXCEPT (source_object, set_number, item_api_name)
	FROM
				    resolved AS unpacked
	    LEFT JOIN 	{{ ref('match_reference_snapshots') }} AS builds USING (match_id)
	    LEFT JOIN 	{{ ref('reference_items') }} AS items
	        ON items.source_object = builds.reference_source_object
	        AND items.set_number = unpacked.tft_set_number
	        AND items.item_api_name = unpacked.item_api_name
	WHERE unpacked.item_api_name IS NOT NULL
)

SELECT *
FROM initial
WHERE
    has_generated_items = False
    OR (has_generated_items = True AND num_tg_items = 1)