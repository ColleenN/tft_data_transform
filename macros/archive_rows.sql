{#
    Moves the raw match detail rows matching `selects` (a SQL condition on
    the landing tables' columns) out of the riot_tap landing tables and into
    an archive dataset. archive_set and archive_before call this; `label`
    names the rows in log messages.

    Rows are matched on a fingerprint of their payload and Singer sequence.
    The copy only adds rows the archive lacks, and the delete only removes
    rows the archive already holds, so any step can be repeated after a
    failure. A matching row that lands between the copy and the check fails
    the check, and nothing is deleted until the next run. Rows that leave
    the landing tables can't be rebuilt by a --full-refresh.

    landing_dataset points the macro at copies of the landing tables
    instead of the riot_tap source, for the integration tests.
#}

{% macro archive_rows(selects, label, archive_dataset, dry_run=false, landing_dataset=none) %}
    {% set row_fp %}FARM_FINGERPRINT(CONCAT(TO_JSON_STRING(data), '|', COALESCE(CAST(_sdc_sequence AS STRING), ''))){% endset %}

    {% for table_name in ['tft_player_match_detail', 'apex_ranked_ladder_match_detail', 'normal_ranked_ladder_match_detail'] %}
        {% if landing_dataset %}
            {% set src = api.Relation.create(database=target.database, schema=landing_dataset, identifier=table_name) %}
        {% else %}
            {% set src = source('riot_tap', table_name) %}
        {% endif %}
        {% set dest = adapter.quote(src.database) ~ '.' ~ adapter.quote(archive_dataset) ~ '.' ~ adapter.quote(table_name) %}

        {% if dry_run %}
            {% set n = run_query("SELECT COUNT(*) FROM " ~ src ~ " WHERE " ~ selects).columns[0].values()[0] %}
            {{ log(table_name ~ ": " ~ n ~ " " ~ label ~ " rows would move to " ~ dest, info=true) }}
        {% else %}
            {% do run_query("CREATE TABLE IF NOT EXISTS " ~ dest ~ " LIKE " ~ src) %}
            {% do run_query(archive_rows_copy_sql(src, dest, selects, row_fp)) %}

            {% set missing, total = run_query(archive_rows_verify_sql(src, dest, selects, row_fp)).rows[0].values() %}
            {% if missing > 0 %}
                {{ exceptions.raise_compiler_error(
                    table_name ~ ": " ~ missing ~ " of " ~ total ~ " rows are missing from the archive; nothing was deleted"
                ) }}
            {% endif %}

            {% do run_query(archive_rows_delete_sql(src, dest, selects, row_fp)) %}
            {{ log(table_name ~ ": archived and removed " ~ total ~ " " ~ label ~ " rows", info=true) }}
        {% endif %}
    {% endfor %}
{% endmacro %}

{% macro archive_rows_copy_sql(src, dest, selects, row_fp) %}
    INSERT INTO {{ dest }}
    SELECT s.* EXCEPT (fp)
    FROM (SELECT *, {{ row_fp }} AS fp FROM {{ src }} WHERE {{ selects }}) AS s
    LEFT JOIN (SELECT DISTINCT {{ row_fp }} AS fp FROM {{ dest }} WHERE {{ selects }}) AS a
        ON s.fp = a.fp
    WHERE a.fp IS NULL
{% endmacro %}

{% macro archive_rows_verify_sql(src, dest, selects, row_fp) %}
    SELECT COUNTIF(a.fp IS NULL) AS missing, COUNT(*) AS total
    FROM (SELECT {{ row_fp }} AS fp FROM {{ src }} WHERE {{ selects }}) AS s
    LEFT JOIN (SELECT DISTINCT {{ row_fp }} AS fp FROM {{ dest }} WHERE {{ selects }}) AS a
        ON s.fp = a.fp
{% endmacro %}

{% macro archive_rows_delete_sql(src, dest, selects, row_fp) %}
    DELETE FROM {{ src }}
    WHERE {{ selects }}
      AND {{ row_fp }} IN (SELECT {{ row_fp }} FROM {{ dest }} WHERE {{ selects }})
{% endmacro %}
