{% macro latest_raw_match_detail(set_num=var('current_set'), env=none) %}
    {% set is_pbe = (env | upper == 'PBE') if env is not none else var('use_pbe_data') %}

    SELECT * EXCEPT (version_major, version_minor)
    FROM (
        SELECT
            *,
            SAFE_CAST(SPLIT(game_client_version_id, '.')[SAFE_OFFSET(0)] AS INT64) AS version_major,
            SAFE_CAST(SPLIT(game_client_version_id, '.')[SAFE_OFFSET(1)] AS INT64) AS version_minor
        FROM {{ ref('unique_matches') }}
        WHERE tft_set_number = {{ set_num }}
            AND {{ '' if is_pbe else 'NOT' }} server_realm_code = 'PBE1'
    )
    WHERE version_major IS NOT NULL AND version_minor IS NOT NULL
    QUALIFY RANK() OVER (ORDER BY version_major DESC, version_minor DESC) = 1
{% endmacro %}
