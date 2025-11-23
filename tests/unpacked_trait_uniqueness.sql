SELECT match_id, puuid, name 
FROM {{ ref('unpacked_traits') }}
GROUP BY match_id, puuid, name
HAVING count(*) > 1