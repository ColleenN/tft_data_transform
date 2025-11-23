SELECT  match_id, puuid,
        placement, level, gold_left, last_round, players_eliminated,
        cumulative_level_cost
FROM
        {{ ref('unpacked_unified') }} AS base
    LEFT JOIN {{ ref('seed_level_costs') }} AS seed USING (level)
GROUP BY 
    match_id, puuid,
    placement, level, gold_left, last_round, players_eliminated,
    cumulative_level_cost