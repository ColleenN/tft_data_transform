{#
    Moves one finished set's raw match detail out of the riot_tap landing
    tables and into an archive dataset:

        dbt run-operation archive_set --args '{set_num: 17, dry_run: true}'
        dbt run-operation archive_set --args '{set_num: 17}'

    Rows are matched on a fingerprint of their payload and Singer sequence.
    The copy only adds rows the archive lacks, and the delete only removes
    rows the archive already holds, so any step can be repeated after a
    failure. A row for the set that lands between the copy and the check
    fails the check, and nothing is deleted until the next run. Since the
    set leaves the landing tables, a --full-refresh can't rebuild it.

    landing_dataset points the macro at copies of the landing tables
    instead of the riot_tap source, for the integration tests.
#}

{% macro archive_set(set_num, archive_dataset=var('archive_dataset', 'match_data_archive'), dry_run=false, landing_dataset=none) %}
    {% if set_num == var('current_set') %}
        {{ exceptions.raise_compiler_error("Refusing to archive set " ~ set_num ~ ": it is current_set") }}
    {% endif %}

    {% set in_set %}SAFE_CAST(JSON_VALUE(data, "$.info.tft_set_number") AS INT64) = {{ set_num }}{% endset %}
    {% set row_fp %}FARM_FINGERPRINT(CONCAT(TO_JSON_STRING(data), '|', COALESCE(CAST(_sdc_sequence AS STRING), ''))){% endset %}

    {% for table_name in ['tft_player_match_detail', 'apex_ranked_ladder_match_detail', 'normal_ranked_ladder_match_detail'] %}
        {% if landing_dataset %}
            {% set src = api.Relation.create(database=target.database, schema=landing_dataset, identifier=table_name) %}
        {% else %}
            {% set src = source('riot_tap', table_name) %}
        {% endif %}
        {% set dest = adapter.quote(src.database) ~ '.' ~ adapter.quote(archive_dataset) ~ '.' ~ adapter.quote(table_name) %}

        {% if dry_run %}
            {% set n = run_query("SELECT COUNT(*) FROM " ~ src ~ " WHERE " ~ in_set).columns[0].values()[0] %}
            {{ log(table_name ~ ": " ~ n ~ " set-" ~ set_num ~ " rows would move to " ~ dest, info=true) }}
        {% else %}
            {% do run_query("CREATE TABLE IF NOT EXISTS " ~ dest ~ " LIKE " ~ src) %}
            {% do run_query(archive_set_copy_sql(src, dest, in_set, row_fp)) %}

            {% set missing, total = run_query(archive_set_verify_sql(src, dest, in_set, row_fp)).rows[0].values() %}
            {% if missing > 0 %}
                {{ exceptions.raise_compiler_error(
                    table_name ~ ": " ~ missing ~ " of " ~ total ~ " rows are missing from the archive; nothing was deleted"
                ) }}
            {% endif %}

            {% do run_query(archive_set_delete_sql(src, dest, in_set, row_fp)) %}
            {{ log(table_name ~ ": archived and removed " ~ total ~ " set-" ~ set_num ~ " rows", info=true) }}
        {% endif %}
    {% endfor %}
{% endmacro %}

{% macro archive_set_copy_sql(src, dest, in_set, row_fp) %}
    INSERT INTO {{ dest }}
    SELECT s.* EXCEPT (fp)
    FROM (SELECT *, {{ row_fp }} AS fp FROM {{ src }} WHERE {{ in_set }}) AS s
    LEFT JOIN (SELECT DISTINCT {{ row_fp }} AS fp FROM {{ dest }} WHERE {{ in_set }}) AS a
        ON s.fp = a.fp
    WHERE a.fp IS NULL
{% endmacro %}

{% macro archive_set_verify_sql(src, dest, in_set, row_fp) %}
    SELECT COUNTIF(a.fp IS NULL) AS missing, COUNT(*) AS total
    FROM (SELECT {{ row_fp }} AS fp FROM {{ src }} WHERE {{ in_set }}) AS s
    LEFT JOIN (SELECT DISTINCT {{ row_fp }} AS fp FROM {{ dest }} WHERE {{ in_set }}) AS a
        ON s.fp = a.fp
{% endmacro %}

{% macro archive_set_delete_sql(src, dest, in_set, row_fp) %}
    DELETE FROM {{ src }}
    WHERE {{ in_set }}
      AND {{ row_fp }} IN (SELECT {{ row_fp }} FROM {{ dest }} WHERE {{ in_set }})
{% endmacro %}
