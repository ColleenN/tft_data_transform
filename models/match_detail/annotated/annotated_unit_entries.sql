{{
    config(
        materialized='incremental',
        unique_key=[
            'match_id',
            'puuid',
            'character_id',
            'tier',
            'unit_instance_index'
        ]
    )
}}

WITH initial_pass as
(
	SELECT *,
	CASE
		WHEN raw_unit_rarity < 3 THEN raw_unit_rarity+1
		WHEN raw_unit_rarity = 6 THEN 5
		ELSE raw_unit_rarity
	END as true_unit_cost,
	CASE
		WHEN raw_unit_rarity < 7 THEN 1
		ELSE 0
	END as shop_unit
	FROM {{ ref('board_unit_data') }}
)
SELECT
    initial_pass.match_id, initial_pass.puuid, initial_pass.character_id,
    initial_pass.tier, initial_pass.unit_instance_index,
    initial_pass.raw_unit_rarity, initial_pass.item_json,
    initial_pass.true_unit_cost, initial_pass.shop_unit,
	CASE
		WHEN shop_unit = 1 THEN true_unit_cost * (3 ^ (initial_pass.tier-1))
		ELSE 0
	END as gold_value,
	jsonb_array_length(item_json) as num_items,
    CASE WHEN ghosts.unit_instance_index IS NULL THEN False ELSE TRUE END AS is_ghost,
    {{ select_item_category_counts() }},
    {{ select_item_component_counts() }}
FROM        initial_pass
    LEFT JOIN {{ ref('ghost_unit_certain') }} ghosts
        ON initial_pass.match_id = ghosts.match_id
        AND initial_pass.puuid = ghosts.puuid
        AND initial_pass.character_id = ghosts.character_id
        AND initial_pass.unit_instance_index = ghosts.unit_instance_index
    LEFT JOIN {{ ref('unit_item_aggregations') }} item_info
        ON initial_pass.match_id = item_info.match_id
        AND initial_pass.puuid = item_info.puuid
        AND initial_pass.character_id = item_info.character_id
        AND initial_pass.unit_instance_index = item_info.unit_instance_index



