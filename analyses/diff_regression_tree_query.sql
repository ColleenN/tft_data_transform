
WITH tmp AS
(
    SELECT *, COUNT(*) OVER (PARTITION BY match_id, puuid, character_id, tier, unit_instance_index) AS item_count
    FROM {{ ref('seed_annotated_unit_items') }}
    QUALIFY item_count = 3
),

tmp2 AS
(
    SELECT match_id, puuid, character_id, tier, cost, total_unit_cost, placement
    FROM tmp
        LEFT JOIN {{ ref('unpacked_boards') }} USING (match_id, puuid)
        LEFT JOIN {{ ref('seed_annotated_units') }} USING (match_id, puuid, character_id, tier, unit_instance_index)
    GROUP BY match_id, puuid, character_id, tier, cost, total_unit_cost, placement
)

SELECT character_id, tier, cost, total_unit_cost, ROUND(AVG(placement)-3.587, 3) AS AVP, count(*) AS sample_size
FROM tmp2
WHERE cost = 3 AND tier = 3
GROUP BY character_id, tier, cost, total_unit_cost
--HAVING count(*) > 100
ORDER BY AVG(placement) ASC

-- 3* 3 cost AVP = 3.587
