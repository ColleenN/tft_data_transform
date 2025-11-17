SELECT *, COUNT(*) OVER (PARTITION BY match_id, puuid, character_id, tier, unit_instance_index) AS item_count
FROM {{ ref('unit_items_seed_annotated') }}
QUALIFY item_count = 3