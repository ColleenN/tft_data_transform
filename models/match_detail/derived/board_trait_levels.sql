WITH unit_traits AS
(
	SELECT match_id, puuid, trait, COUNT(*) AS num_units_in_record
	FROM {{ ref('unit_trait_contributions') }}
	GROUP BY match_id, puuid, trait
)

SELECT 	active.match_id, active.puuid, trait,
		active.tier_current tier_active,
		active.num_units active_count, counted.num_units_in_record on_board_count,
		active.num_units-counted.num_units_in_record AS raw_diff
FROM
				{{ ref('board_active_trait_data') }} active
	LEFT JOIN 	unit_traits counted
		ON active.match_id = counted.match_id
		AND active.puuid = counted.puuid
		AND active.name = counted.trait