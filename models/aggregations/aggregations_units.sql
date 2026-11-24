WITH excluded_units AS (
    SELECT DISTINCT match_id, puuid, character_id, tier, unit_instance_index, TRUE AS is_excluded
    FROM {{ ref('unit_adjustments') }}
    WHERE adjustment = 'exclude_from_board'
)

SELECT  match_id, puuid, character_id, tier, unit_instance_index,
        shop_unit, num_board_slots, rarity, total_unit_cost,
        IFNULL(is_excluded, FALSE) AS excluded_from_board,
        CASE WHEN num_tg_items IS NULL THEN 0 ELSE num_tg_items END AS tg_item,
        COUNT(item_api_name) AS num_items,
        {{ select_item_category_sums() }},
        {{ select_item_component_sums() }}
FROM            {{ ref('seed_annotated_unified') }}
    LEFT JOIN   excluded_units
        USING (match_id, puuid, character_id, tier, unit_instance_index)
GROUP BY    match_id, puuid,
            character_id, tier, unit_instance_index,
            shop_unit, num_board_slots, rarity, total_unit_cost,
            excluded_from_board, num_tg_items
