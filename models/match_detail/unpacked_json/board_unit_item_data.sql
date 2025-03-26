WITH initial AS (
    SELECT
	    match_id,
        puuid,
        character_id,
        tier,
        unit_instance_index,
        jsonb_array_elements_text(item_json) as item_api_name
    FROM {{ ref('board_unit_data') }}
)

SELECT  *,
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






--