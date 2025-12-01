SELECT * 
FROM            {{ ref('aggregations_boards') }}
    LEFT JOIN   {{  ref('traits_pivoted') }} USING (match_id, puuid)
WHERE num_unit_slots < num_units AND TFT16_EXPLORER = 0
AND match_id = 'PBE1_4520437160' AND puuid = 'lqeko_0ZLfrVm-MchgzAXhaR-d8EEhKis-Ksoa8mJSoQbpgVYxB2ZI7EZakrQpTod__VulpQodjoBA'
