{{
    config(
        materialized='incremental',
        unique_key=['match_id', 'puuid', 'character_id', 'tier', 'unit_instance_index', 'item_api_name', 'item_instance_index']
    )
}}

SELECT 
    boards.match_id, boards.puuid, placement, level, gold_left, last_round, players_eliminated,
    units.character_id, units.tier, units.unit_instance_index, raw_unit_rarity, 
    item_api_name, item_instance_index
FROM            {{ ref('unpacked_board') }} AS boards
    LEFT JOIN   {{ ref('unpacked_units') }} AS units 
        USING (match_id, puuid)
    LEFT JOIN   {{ ref('unpacked_unit_items') }} AS items 
        USING (match_id, puuid, character_id, tier, unit_instance_index)