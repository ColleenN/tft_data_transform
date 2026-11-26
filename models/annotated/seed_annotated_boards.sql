SELECT  base.match_id, base.puuid, base.tft_set_number,
        base.placement, base.level, base.gold_left, base.last_round, base.players_eliminated,
        seed.cumulative_level_cost
FROM
        {{ ref('unpacked_unified') }} AS base
    LEFT JOIN {{ ref('seed_level_costs') }} AS seed
        ON seed.set_num = base.tft_set_number
        AND seed.level = base.level
GROUP BY
    base.match_id, base.puuid, base.tft_set_number,
    base.placement, base.level, base.gold_left, base.last_round, base.players_eliminated,
    seed.cumulative_level_cost
