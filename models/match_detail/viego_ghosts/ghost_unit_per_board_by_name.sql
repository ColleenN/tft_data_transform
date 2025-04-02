WITH ambiguous AS
(
	SELECT known.match_id, known.puuid
		FROM 			{{ ref('ghost_board_known') }} known
			LEFT JOIN 	{{ ref('ghost_possible_by_traits') }} poss_trait
				ON known.match_id = poss_trait.match_id
				AND known.puuid = poss_trait.puuid
	WHERE poss_trait.character_id IS NULL
),
dupe_units AS
(
	SELECT ambiguous.match_id, ambiguous.puuid, units.character_id
	FROM 			ambiguous
		LEFT JOIN 	{{ ref('board_unit_data') }} units
			ON ambiguous.match_id = units.match_id
			AND ambiguous.puuid = units.puuid
	GROUP BY ambiguous.match_id, ambiguous.puuid, units.character_id
	HAVING COUNT(*) > 1
),

by_unit_name AS
(
	SELECT ambiguous.match_id, ambiguous.puuid, dupe_units.character_id
	FROM 			ambiguous
		LEFT JOIN 	dupe_units
			ON ambiguous.match_id = dupe_units.match_id
			AND ambiguous.puuid = dupe_units.puuid
	UNION
	SELECT known.match_id, known.puuid, poss_trait.character_id
		FROM 			dbt.ghost_board_known known
			LEFT JOIN 	dbt.ghost_possible_by_traits poss_trait
				ON known.match_id = poss_trait.match_id
				AND known.puuid = poss_trait.puuid
	WHERE poss_trait.character_id IS NOT NULL

)
SELECT *
FROM 			by_unit_name
	LEFT JOIN 	{{ ref('unit_item_aggregations') }} units
		ON by_unit_name.match_id = units.match_id
		AND by_unit_name.puuid = units.puuid
		AND by_unit_name.character_id = units.character_id
		AND units.num_craftables = 1 AND units.num_emblems = 0
