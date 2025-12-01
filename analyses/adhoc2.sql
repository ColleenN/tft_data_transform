SELECT *
FROM {{ ref('unpacked_unit_items') }}
WHERE match_id = 'PBE1_4520437160' AND puuid = 'lqeko_0ZLfrVm-MchgzAXhaR-d8EEhKis-Ksoa8mJSoQbpgVYxB2ZI7EZakrQpTod__VulpQodjoBA'

ORDER BY character_id