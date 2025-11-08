WITH initial AS (
    SELECT
	    match_id,
        puuid,
        character_id,
        tier,
        unit_instance_index,
        JSON_EXTRACT_SCALAR(items, "$") AS item_api_name
    FROM {{ ref('unpacked_units') }},
    UNNEST(JSON_EXTRACT_ARRAY(item_list, "$.")) AS items
)
SELECT *,
    row_number() OVER (
        PARTITION BY
            match_id,
            puuid,
            character_id,
            tier,
            unit_instance_index,
            item_api_name
    )
    AS item_instance_index
FROM initial