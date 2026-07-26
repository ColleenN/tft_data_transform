SELECT match_id
FROM {{ ref('with_patch') }}
GROUP BY match_id
HAVING COUNT(*) > 1
