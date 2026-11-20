{{ config(materialized='incremental') }}

SELECT *
FROM            {{ ref('seed_annotated_boards') }} AS boards
    LEFT JOIN   {{ ref('seed_annotated_units') }} USING (match_id, puuid)
    LEFT JOIN   {{ ref('seed_annotated_unit_items') }}
        USING (match_id, puuid, character_id, tier, unit_instance_index)
{% if is_incremental() %}
WHERE match_id NOT IN (SELECT match_id FROM {{ this }})
{% endif %}
