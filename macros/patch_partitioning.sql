{% macro latest_live(set_num=var('current_set')) %}
    SELECT * FROM dbt_output_current_set_raw.unique_matches
    WHERE game_client_version_id =
    (
        SELECT MAX(game_client_version_id)
        FROM dbt_output_current_set_raw.unique_matches
        WHERE tft_set_number = {{ set_num }} AND NOT server_realm_code = 'PBE1'
    ) AND
    tft_set_number = {{ set_num }} AND NOT server_realm_code = 'PBE1'
{% endmacro %}

{% macro latest_pbe(set_num=var('current_set')) %}
    SELECT * FROM dbt_output_current_set_raw.unique_matches
    WHERE game_client_version_id =
    (
        SELECT MAX(game_client_version_id)
        FROM dbt_output_current_set_raw.unique_matches
        WHERE tft_set_number = {{ set_num }} AND server_realm_code = 'PBE1'
    ) AND
    tft_set_number = {{ set_num }} AND server_realm_code = 'PBE1'
{% endmacro %}

{% macro latest_raw_match_detail(set_num=var('current_set'), env=none) %}
    {% if env|upper == 'PBE' or (env is none and var('use_pbe_data')) %}
        {{ latest_pbe(set_num) }}
    {% else %}
        {{ latest_live(set_num) }}
    {% endif %}
{% endmacro %}

