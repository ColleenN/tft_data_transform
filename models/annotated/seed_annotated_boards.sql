SELECT *
FROM
        {{ ref('unpacked_unified') }} AS base
    LEFT JOIN {{ ref('seed_level_costs') }} AS seed USING (level)