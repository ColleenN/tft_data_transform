-- Match records sometimes name a unit differently from the reference data
-- (seed_unit_aliases), so units are reported under the reference name.
WITH initial AS
(
    SELECT match_id, puuid, boards.tft_set_number,
        UPPER(JSON_VALUE(units, '$.character_id')) AS character_id,
        CAST(JSON_VALUE(units, '$.tier') AS INT64) AS tier,
        CAST(JSON_VALUE(units, '$.rarity') AS INT64) AS raw_unit_rarity,
        JSON_QUERY(units, '$.itemNames') AS item_list,
        unit_position
    FROM    {{ ref('unpacked_boards') }} AS boards, 
            UNNEST(JSON_EXTRACT_ARRAY(unit_list, "$.")) AS units WITH OFFSET AS unit_position
),

resolved AS
(
    SELECT
        initial.* EXCEPT (character_id, tft_set_number),
        COALESCE(aliases.character_id, initial.character_id) AS character_id
    FROM
                    initial
        LEFT JOIN   {{ ref('seed_unit_aliases') }} AS aliases
            ON aliases.set_num = initial.tft_set_number
            AND aliases.match_character_id = initial.character_id
)

SELECT
	match_id, puuid, character_id, tier, raw_unit_rarity,
	row_number() OVER (PARTITION BY match_id, puuid, character_id, tier ORDER BY unit_position) unit_instance_index,
	item_list
FROM resolved
