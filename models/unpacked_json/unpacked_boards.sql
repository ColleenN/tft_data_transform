SELECT
    match_id,
    JSON_VALUE(players, '$.puuid') AS puuid,
    CAST(JSON_VALUE(players, '$.placement') AS INT64) AS placement,
    CAST(JSON_VALUE(players, '$.level') AS INT64) AS level,
    CAST(JSON_VALUE(players, '$.gold_left') AS INT64) AS gold_left,
    CAST(JSON_VALUE(players, '$.last_round') AS INT64) AS last_round,
    CAST(JSON_VALUE(players, '$.players_eliminated') AS INT64) AS players_eliminated,
    JSON_QUERY(players, '$.units') AS unit_list,
    JSON_QUERY(players, '$.traits') AS trait_list
FROM ({{ latest_live(16) }}) AS matches,
    UNNEST(JSON_EXTRACT_ARRAY(matches.info, "$.participants")) AS players