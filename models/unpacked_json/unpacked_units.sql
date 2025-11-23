WITH initial AS
(
    SELECT match_id, puuid,
        JSON_VALUE(units, '$.character_id') AS character_id,
        CAST(JSON_VALUE(units, '$.tier') AS INT64) AS tier,
        CAST(JSON_VALUE(units, '$.rarity') AS INT64) AS raw_unit_rarity,
        JSON_QUERY(units, '$.itemNames') AS item_list
    FROM    {{ ref('unpacked_boards') }} AS boards, 
            UNNEST(JSON_EXTRACT_ARRAY(unit_list, "$.")) AS units
)
SELECT
	match_id, puuid, character_id, tier, raw_unit_rarity,
	row_number() OVER (PARTITION BY match_id, puuid, character_id, tier) unit_instance_index,
	item_list
FROM initial