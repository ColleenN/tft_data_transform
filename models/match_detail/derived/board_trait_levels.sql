WITH unit_traits AS
(
	SELECT match_id, puuid, trait, COUNT(*) AS num_units_in_record
	FROM {{ ref('unit_trait_contributions') }}
	GROUP BY match_id, puuid, trait
),
matched_to_active AS
(
	SELECT 	counted.match_id, counted.puuid, trait,
		CASE WHEN active.tier_current IS NULL THEN 0 ELSE active.tier_current END tier_active,
		CASE WHEN active.num_units  IS NULL THEN 0 ELSE active.num_units END active_count,
		counted.num_units_in_record on_board_count
	FROM
				unit_traits counted
	LEFT JOIN 	{{ ref('board_active_trait_data') }} active
		ON active.match_id = counted.match_id
		AND active.puuid = counted.puuid
		AND active.name = counted.trait
)
SELECT
	*,
	active_count - on_board_count AS raw_diff
FROM matched_to_active