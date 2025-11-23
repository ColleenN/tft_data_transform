SELECT *, COUNT(*) OVER (PARTITION BY match_id, puuid, character_id, tier, unit_instance_index) AS item_count
FROM {{ ref('seed_annotated_unit_items') }}
QUALIFY item_count = 3