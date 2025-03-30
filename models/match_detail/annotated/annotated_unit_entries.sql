{{
    config(
        materialized='incremental'
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
    match_id, puuid, character_id, tier, unit_instance_index, raw_unit_rarity, item_json,
    true_unit_cost, shop_unit,
	CASE
		WHEN shop_unit = 1 THEN true_unit_cost * (3 ^ (tier-1))
		ELSE 0
	END as gold_value,
	jsonb_array_length(item_json) as num_items
FROM initial_pass

-- TODO: remove ghost units from calculations

