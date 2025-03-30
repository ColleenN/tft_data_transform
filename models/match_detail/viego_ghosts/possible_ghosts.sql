WITH possible_ghosts AS
(
	SELECT 		boards.match_id, boards.puuid, boards.trait, character_id
	FROM 			{{ ref('board_trait_levels') }} boards
		LEFT JOIN 	{{ ref('unit_trait_contributions') }} units
			ON boards.match_id = units.match_id
			AND boards.puuid = units.puuid
			AND boards.trait = units.trait
	WHERE raw_diff = -1
),
all_ghost_scores AS
(
	SELECT
		possible_ghosts.match_id,
		possible_ghosts.puuid,
		possible_ghosts.character_id,
		COUNT(*) as ghost_score
	FROM 			possible_ghosts
	GROUP BY possible_ghosts.match_id, possible_ghosts.puuid, possible_ghosts.character_id
),
high_ghost_scores AS
(SELECT match_id, puuid, MAX(ghost_score) high_score FROM all_ghost_scores GROUP BY match_id, puuid)

SELECT  all_ghost_scores.match_id,
        all_ghost_scores.puuid,
        all_ghost_scores.character_id
FROM all_ghost_scores INNER JOIN high_ghost_scores
	ON all_ghost_scores.match_id = high_ghost_scores.match_id
	AND all_ghost_scores.puuid = high_ghost_scores.puuid
	AND all_ghost_scores.ghost_score = high_ghost_scores.high_score