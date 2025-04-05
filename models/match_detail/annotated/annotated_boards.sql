{{
    config(
        materialized='incremental',
        unique_key=[
            'match_id',
            'puuid'
        ]
    )
}}

WITH unit_aggregations as
(
	SELECT 	board.match_id, board.puuid,
			SUM(gold_value) AS total_board_gold_value,
			SUM(num_items) AS total_num_items,
	        {{ select_item_category_sums() }},
            {{ select_item_component_sums() }}
	FROM 			{{ ref('base_board_data') }} board
		LEFT JOIN 	{{ ref('annotated_unit_entries') }} unit
			ON board.match_id = unit.match_id AND board.puuid = unit.puuid
	WHERE is_ghost = False
	GROUP BY board.match_id, board.puuid
)

SELECT 	board.match_id, board.puuid,
		placement, level, gold_left,
		time_eliminated, players_eliminated, total_damage_to_players, rounds_played,
		total_board_gold_value, total_num_items,
        {{ select_item_category_counts() }},
        {{ select_item_component_counts() }}
FROM 	{{ ref('base_board_data') }} board
        {{ join_on_board_id('board', 'unit_aggregations') }}