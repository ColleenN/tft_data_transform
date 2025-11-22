SELECT game_client_version_id
FROM ({{ latest_raw_match_detail() }})
group by game_client_version_id