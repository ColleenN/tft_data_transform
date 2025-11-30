SELECT  match_id, puuid, level,
        level + SUM(num_tac_items) AS num_unit_slots,
        SUM(CASE WHEN shop_unit AND NOT character_id = 'TFT16_GALIO' THEN 1 ELSE 0 END) AS num_units,
        SUM(num_items) AS num_items,
        {{ select_item_category_sums() }},
        {{ select_item_component_sums() }}

FROM            {{ ref('seed_annotated_boards') }}
    LEFT JOIN   {{ ref('aggregations_units') }} USING (match_id, puuid)
GROUP BY match_id, puuid, level
HAVING num_units > num_unit_slots