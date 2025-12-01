SELECT *
FROM            {{ ref('seed_annotated_boards') }}
    LEFT JOIN   {{ ref('aggregations_boards') }} USING (match_id, puuid)
WHERE match_id = 'PBE1_4520968292'