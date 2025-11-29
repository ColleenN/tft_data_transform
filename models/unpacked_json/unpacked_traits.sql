SELECT match_id, puuid,
    UPPER(JSON_VALUE(traits, '$.name')) AS name,
    CAST(JSON_VALUE(traits, '$.num_units') AS INT64) AS num_units,
    CAST(JSON_VALUE(traits, '$.tier_current') AS INT64) AS tier_current
FROM    {{ ref('unpacked_boards') }} AS boards, 
        UNNEST(JSON_EXTRACT_ARRAY(trait_list, "$.")) AS traits