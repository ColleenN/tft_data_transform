{{
    config(
        materialized='incremental'
    )
}}

WITH from_emblem AS
(
	SELECT match_id, puuid, character_id, trait_granted as trait
	FROM {{ ref('annotated_unit_item_entries') }}
	WHERE trait_granted IS NOT NULL
),
innate AS
(
	SELECT match_id, puuid, character_id, trait
	FROM
		            {{ ref('board_unit_data') }} unit
		LEFT JOIN   {{ ref('seed_unit_innate_traits') }} trait
	                ON unit.character_id = trait.api_name
	WHERE trait IS NOT NULL
)

SELECT DISTINCT *
FROM from_emblem
UNION
SELECT DISTINCT *
FROM innate