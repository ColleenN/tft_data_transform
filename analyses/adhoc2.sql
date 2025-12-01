SELECT *
FROM {{ ref('unpacked_unit_items') }}
WHERE match_id = 'PBE1_4519783611' AND puuid = 'q5_-8YzxLhgHvDx6EDUuhowfskghF_qL7m7c37Ij5mfTMasb1NFiYatdZSTFd1b2AQWGxB_lXDkDDQ'

ORDER BY character_id