SELECT game_client_version_id, patch_major_id, patch_minor_id
FROM dbt_output_current_set_raw.with_patch
WHERE 
    --    patch_major_id = 1
    --AND patch_minor_id = CAST(b AS STRING)
    --AND 
    tft_set_number = 16
    AND NOT server_realm_code = 'PBE1' --AND 
    -- (
    --     game_client_version_id = '15.24.730.0505' OR 
    --     game_client_version_id = '15.24.733.5841'
    -- )
GROUP BY game_client_version_id, patch_major_id, patch_minor_id
ORDER BY game_client_version_id