{% macro latest_game_version(set_num, is_pbe) %}
    {% set query %}
    SELECT
        SAFE_CAST(SPLIT(game_client_version_id, '.')[SAFE_OFFSET(0)] AS INT64) AS version_major,
        SAFE_CAST(SPLIT(game_client_version_id, '.')[SAFE_OFFSET(1)] AS INT64) AS version_minor
    FROM {{ ref('unique_matches') }}
    WHERE tft_set_number = {{ set_num }}
        AND (server_realm_code = 'PBE1') = {{ is_pbe }}
    ORDER BY version_major DESC NULLS LAST, version_minor DESC NULLS LAST
    LIMIT 1
    {% endset %}

    {% if not execute %}
        {{ return((none, none)) }}
    {% endif %}

    {% set rows = run_query(query).rows %}
    {% if rows | length == 0 or rows[0][0] is none %}
        {{ exceptions.raise_compiler_error(
            "No " ~ ("PBE" if is_pbe else "live") ~ " matches with a game version for set " ~ set_num
        ) }}
    {% endif %}
    {{ return(rows[0].values()) }}
{% endmacro %}

{% macro latest_raw_match_detail(set_num=var('current_set'), env=none) %}
    {% set is_pbe = (env | upper == 'PBE') if env is not none else var('use_pbe_data') %}
    {% set major, minor = latest_game_version(set_num, is_pbe) %}

    SELECT * FROM {{ ref('unique_matches') }}
    WHERE
            STARTS_WITH(game_client_version_id, '{{ major }}.{{ minor }}.')
        AND tft_set_number = {{ set_num }}
        AND {{ '' if is_pbe else 'NOT' }} server_realm_code = 'PBE1'
{% endmacro %}
