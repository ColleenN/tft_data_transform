{#
    Moves one finished set's raw match detail out of the riot_tap landing
    tables and into an archive dataset (see archive_rows):

        dbt run-operation archive_set --args '{set_num: 17, dry_run: true}'
        dbt run-operation archive_set --args '{set_num: 17}'
#}

{% macro archive_set(set_num, archive_dataset=var('archive_dataset', 'match_data_archive'), dry_run=false, landing_dataset=none) %}
    {% if set_num == var('current_set') %}
        {{ exceptions.raise_compiler_error("Refusing to archive set " ~ set_num ~ ": it is current_set") }}
    {% endif %}

    {% set in_set %}SAFE_CAST(JSON_VALUE(data, "$.info.tft_set_number") AS INT64) = {{ set_num }}{% endset %}
    {% do archive_rows(in_set, "set-" ~ set_num, archive_dataset, dry_run=dry_run, landing_dataset=landing_dataset) %}
{% endmacro %}
