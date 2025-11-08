WITH viego_boards AS
(
	SELECT match_id, puuid FROM {{ ref('board_unit_data') }}
	WHERE character_id = 'TFT14_Viego'
	GROUP BY match_id, puuid
),

tac_item_totals AS
(
	SELECT match_id, puuid, SUM(num_tac_items) AS num_tac_items
	FROM {{ ref('unit_item_aggregations') }}
	GROUP BY match_id, puuid
),

excess_unit_boards AS
(
	SELECT board.match_id, board.puuid, board.level, COUNT(*) AS num_units,
	       COUNT(*) - board.level AS num_excess_units
	FROM 			{{ ref('base_board_data') }} board
		LEFT JOIN 	{{ ref('board_unit_data') }} units
			ON board.match_id = units.match_id
			AND board.puuid = units.puuid
	WHERE raw_unit_rarity < 7 AND NOT character_id LIKE 'TFT14_Summon%'
	GROUP BY board.match_id, board.puuid, board.level
	HAVING COUNT(*) > board.level
)

SELECT excess_unit_boards.match_id, excess_unit_boards.puuid
FROM
				excess_unit_boards
	LEFT JOIN	viego_boards
		ON excess_unit_boards.match_id = viego_boards.match_id
		AND excess_unit_boards.puuid = viego_boards.puuid
	LEFT JOIN 	tac_item_totals
		ON excess_unit_boards.match_id = tac_item_totals.match_id
		AND excess_unit_boards.puuid = tac_item_totals.puuid
WHERE num_excess_units - num_tac_items > 0 AND viego_boards.match_id IS NOT NULL