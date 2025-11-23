WITH zoe_3_games AS
(
    SELECT match_id, puuid
        FROM {{ ref('seed_annotated_unified') }}
    WHERE character_id = 'TFT16_Zoe' AND tier = 3
    GROUP BY match_id, puuid
    HAVING count(*) = 3
)

SELECT match_id, puuid, character_id, tier, unit_instance_index, placement, level
FROM zoe_3_games 
    LEFT JOIN {{ ref('seed_annotated_unified') }} USING (match_id, puuid)
WHERE character_id = 'TFT16_AurelionSol' AND tier = 1
GROUP BY match_id, puuid, character_id, tier, unit_instance_index, placement, level
ORDER BY placement
