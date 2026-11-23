{#
    In the ci target, every table name gets DBT_CI_TABLE_PREFIX, so pull
    request checks running at the same time each use their own tables in
    the shared CI datasets. Other targets are unchanged.
#}

{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- set alias = default__generate_alias_name(custom_alias_name, node) -%}
    {%- if target.name == 'ci' -%}
        {{ env_var('DBT_CI_TABLE_PREFIX', '') ~ alias }}
    {%- else -%}
        {{ alias }}
    {%- endif -%}
{%- endmacro %}
