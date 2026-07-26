SELECT *
FROM            {{ ref('unique_matches') }} AS matches
    LEFT JOIN   {{ ref('seed_patch_map') }} AS patches
        ON matches.tft_set_number = patches.set_num
        AND matches.game_client_version_id = patches.client_version
        AND matches.server_side_game_start >= patches.datetime_min
        AND matches.server_side_game_start <= patches.datetime_max