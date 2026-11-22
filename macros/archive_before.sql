{#
    Moves raw match detail for games created before `cutoff` out of the
    riot_tap landing tables and into an archive dataset (see archive_rows),
    whatever their set:

        dbt run-operation archive_before --args '{cutoff: "2026-11-18 01:35:37+00", dry_run: true}'

    Used to drop matches from before Patchsieve deploy tracking began, since
    their build can't be worked out. Rows without a readable gameCreation
    never move.
#}

{% macro archive_before(cutoff, archive_dataset=var('archive_dataset', 'match_data_archive'), dry_run=false, landing_dataset=none) %}
    {% set before_cutoff %}TIMESTAMP_MILLIS(SAFE_CAST(JSON_VALUE(data, "$.info.gameCreation") AS INT64)) < TIMESTAMP "{{ cutoff }}"{% endset %}
    {% do archive_rows(before_cutoff, "pre-" ~ cutoff, archive_dataset, dry_run=dry_run, landing_dataset=landing_dataset) %}
{% endmacro %}
