{% macro latest_live(set_num=var('current_set')) %}
    {% set query %}
    SELECT patch_major_id, patch_minor_id
    FROM {{ ref('seed_patch_map') }}
    WHERE set_num = {{ set_num }} AND is_pbe = FALSE
    ORDER BY patch_major_id DESC, patch_minor_id DESC
    LIMIT 1
    {% endset %}

    {% if execute %}
    {% set major, minor = run_query(query).rows[0].values() %}
    {% else %}
    {% set major, minor = "", "" %}
    {% endif %} 

    SELECT * FROM dbt_output_current_set_raw.with_patch
    WHERE 
            patch_major_id = {{ major }} 
        AND patch_minor_id = CAST("{{ minor }}" AS STRING)
        AND tft_set_number = {{ set_num }} 
        AND NOT server_realm_code = 'PBE1'
{% endmacro %}

{% macro latest_pbe(set_num=var('current_set')) %}
    {% set query %}
    SELECT patch_major_id, patch_minor_id
    FROM {{ ref('seed_patch_map') }}
    WHERE set_num = {{ set_num }} AND is_pbe = true
    ORDER BY patch_major_id DESC, patch_minor_id DESC
    LIMIT 1
    {% endset %}

    {% if execute %}
    {% set major, minor = run_query(query).rows[0].values() %}
    {% else %}
    {% set major, minor = "", "" %}
    {% endif %}

    SELECT * FROM dbt_output_current_set_raw.with_patch
    WHERE 
            patch_major_id = {{ major }} 
        AND patch_minor_id = CAST({{ minor }} AS STRING)
        AND tft_set_number = {{ set_num }} 
        AND server_realm_code = 'PBE1'
{% endmacro %}

{% macro latest_raw_match_detail(set_num=var('current_set'), env=none) %}
    {% if env|upper == 'PBE' or (env is none and var('use_pbe_data')) %}
        {{ latest_pbe(set_num) }}
    {% else %}
        {{ latest_live(set_num) }}
    {% endif %}
{% endmacro %}

