WITH initial AS
(
    SELECT
        match_id,
        puuid,
        jsonb_array_elements(unit_list)->>'character_id' as character_id,
        (jsonb_array_elements(unit_list)->>'tier')::int as tier,
        (jsonb_array_elements(unit_list)->>'rarity')::int as raw_unit_rarity,
        jsonb_array_elements(unit_list)->'itemNames' as item_json,
        jsonb_array_elements(unit_list) as raw_unit_json
    FROM {{ ref('base_board_data') }}
)

SELECT
	match_id, puuid, character_id, tier, raw_unit_rarity,
	row_number() OVER (PARTITION BY match_id, puuid, character_id, tier) unit_instance_index,
	item_json, raw_unit_json
FROM initial
