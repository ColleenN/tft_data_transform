{% macro latest_raw_match_detail(set_num=var('current_set'), env=none) %}
    {% set is_pbe = (env | upper == 'PBE') if env is not none else var('use_pbe_data') %}

    SELECT matches.*
    FROM            {{ ref('unique_matches') }} AS matches
        INNER JOIN  {{ ref('match_reference_snapshots') }} AS builds USING (match_id)
    WHERE matches.tft_set_number = {{ set_num }}
        AND builds.channel = '{{ 'pbe' if is_pbe else 'live' }}'
        AND builds.patch IS NOT NULL
    QUALIFY RANK() OVER (
        ORDER BY
            SAFE_CAST(SPLIT(builds.patch, '.')[SAFE_OFFSET(0)] AS INT64) DESC,
            SAFE_CAST(SPLIT(builds.patch, '.')[SAFE_OFFSET(1)] AS INT64) DESC
    ) = 1
{% endmacro %}
