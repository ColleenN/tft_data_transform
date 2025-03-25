{{
    config(
        materialized='incremental'
    )
}}

WITH unit_aggregations as
(
	SELECT 	board.match_id, board.puuid,
			SUM(gold_value) AS total_board_gold_value,
			SUM(num_items) AS total_num_items
	FROM 			{{ ref('base_board_data') }} board
		LEFT JOIN 	{{ ref('annotated_unit_entries') }} unit
			ON board.match_id = unit.match_id AND board.puuid = unit.puuid
	GROUP BY board.match_id, board.puuid
)

SELECT 	board.match_id, board.puuid,
		placement, level, gold_left,
		stage_eliminated, round_eliminated, time_eliminated,
		players_eliminated, total_damage_to_players,

		CASE
			WHEN stage_eliminated > 1 AND round_eliminated < 4 THEN ((stage_eliminated-2) * 5) + round_eliminated
			WHEN stage_eliminated > 1 AND round_eliminated > 3 AND round_eliminated < 7 THEN ((stage_eliminated-2) * 5) + round_eliminated - 1
			WHEN stage_eliminated > 1 AND round_eliminated > 6 THEN (stage_eliminated-1) * 5
			ELSE 0
		END as player_rounds_fought,
		total_board_gold_value, total_num_items

FROM 			{{ ref('base_board_data') }} board
	LEFT JOIN 	unit_aggregations
		ON board.match_id = unit_aggregations.match_id AND board.puuid = unit_aggregations.puuid