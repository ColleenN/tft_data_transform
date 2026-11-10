{% macro latest_patch(set_num, is_pbe) %}
    {% set query %}
    SELECT patch_major_id, CAST(patch_minor_id AS STRING) AS patch_minor_id
    FROM {{ ref('seed_patch_map') }}
    WHERE set_num = {{ set_num }} AND is_pbe = {{ is_pbe }}
    ORDER BY patch_major_id DESC, patch_minor_id DESC
    LIMIT 1
    {% endset %}

    {% if not execute %}
        {{ return((none, none)) }}
    {% endif %}

    {% set rows = run_query(query).rows %}
    {% if rows | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "seed_patch_map has no " ~ ("PBE" if is_pbe else "live") ~ " patches for set " ~ set_num
        ) }}
    {% endif %}
    {{ return(rows[0].values()) }}
{% endmacro %}

{% macro latest_raw_match_detail(set_num=var('current_set'), env=none) %}
    {% set is_pbe = (env | upper == 'PBE') if env is not none else var('use_pbe_data') %}
    {% set major, minor = latest_patch(set_num, is_pbe) %}

    SELECT * FROM {{ ref('with_patch') }}
    WHERE
            patch_major_id = {{ major if major is not none else 'NULL' }}
        AND patch_minor_id = '{{ minor }}'
        AND tft_set_number = {{ set_num }}
        AND {{ '' if is_pbe else 'NOT' }} server_realm_code = 'PBE1'
{% endmacro %}
