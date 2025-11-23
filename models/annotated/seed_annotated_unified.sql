{{
    config(
        materialized='incremental',
        unique_key=['match_id', 'puuid', 'character_id', 'tier', 'unit_instance_index', 'item_api_name', 'item_instance_index']
    )
}}

SELECT *
FROM            {{ ref('seed_annotated_boards') }} AS boards
    LEFT JOIN   {{ ref('seed_annotated_units') }} AS units 
        USING (match_id, puuid)
    LEFT JOIN   {{ ref('seed_annotated_unit_items') }} AS items 
        USING (match_id, puuid, character_id, tier, unit_instance_index)