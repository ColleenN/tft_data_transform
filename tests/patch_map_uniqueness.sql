SELECT client_version, datetime_min, datetime_max 
FROM {{ ref('seed_patch_map') }}
GROUP BY client_version, datetime_min, datetime_max
HAVING COUNT(*) > 1