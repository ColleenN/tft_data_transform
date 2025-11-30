SELECT *

FROM  {{ ref('aggregations_units') }} USING (match_id, puuid)
WHERE match_id = 'PBE1_4520884744' AND puuid = 'zeBT3QXYiqxdevUo2M1sACsMRENy05VlJFmbPmFtxvXvGqe7AMhxzoVXeFApnwRmW08YUvn5qXdudw'