{#
    Archives every set that a newer set has replaced, for a scheduled job:

        dbt run-operation archive_finished_sets --args '{dry_run: true}'
        dbt run-operation archive_finished_sets

    There's no published set release schedule, so the landing data decides.
    A set counts as released once its first ranked match (or PBE normal
    match, as in unique_matches) is more than grace_days old, in any realm.
    New sets reach PBE a couple of weeks before live, so the default of 28
    days lands about two weeks after live launch. Other queues are ignored,
    since revival modes can carry an older set number.

    Every set number below the newest released set that still has rows in
    the landing tables goes to archive_set, oldest first. archive_set still
    refuses var('current_set'), so the job fails on the old set until
    current_set is bumped.

    as_of replaces the current time, for the integration tests.
#}

{% macro archive_finished_sets(grace_days=var('archive_grace_days', 28), archive_dataset=var('archive_dataset', 'match_data_archive'), dry_run=false, landing_dataset=none, as_of=none) %}
    {% set tables = [] %}
    {% for table_name in ['tft_player_match_detail', 'apex_ranked_ladder_match_detail', 'normal_ranked_ladder_match_detail'] %}
        {% if landing_dataset %}
            {% do tables.append(api.Relation.create(database=target.database, schema=landing_dataset, identifier=table_name)) %}
        {% else %}
            {% do tables.append(source('riot_tap', table_name)) %}
        {% endif %}
    {% endfor %}

    {% set result = run_query(archive_finished_sets_sql(tables, grace_days, as_of)) %}
    {% set released = result.rows[0]['released_set'] if result.rows else none %}
    {% set finished = result.columns['set_num'].values() | reject('none') | list %}

    {% if released is none %}
        {{ log("No set has been out for " ~ grace_days ~ " days; nothing to archive", info=true) }}
    {% elif not finished %}
        {{ log("Newest released set is " ~ released ~ "; no older sets left in the landing tables", info=true) }}
    {% else %}
        {{ log("Newest released set is " ~ released ~ "; archiving sets " ~ finished | join(', '), info=true) }}
        {% for set_num in finished %}
            {% do archive_set(set_num, archive_dataset=archive_dataset, dry_run=dry_run, landing_dataset=landing_dataset) %}
        {% endfor %}
    {% endif %}
{% endmacro %}

{#
    One row per finished set (ascending), each carrying the newest released
    set. A single row with a NULL set_num means no set is finished.
#}
{% macro archive_finished_sets_sql(tables, grace_days, as_of) %}
    WITH landed AS (
        {% for t in tables %}
        SELECT
            SAFE_CAST(JSON_VALUE(data, "$.info.tft_set_number") AS INT64) AS set_num,
            TIMESTAMP_MILLIS(SAFE_CAST(JSON_VALUE(data, "$.info.gameCreation") AS INT64)) AS game_start,
            SPLIT(JSON_VALUE(data, "$.metadata.match_id"), '_')[SAFE_OFFSET(0)] AS realm,
            JSON_VALUE(data, "$.info.queue_id") AS queue_id
        FROM {{ t }}
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    ),

    released AS (
        SELECT MAX(set_num) AS released_set
        FROM landed
        WHERE set_num IS NOT NULL
            AND ((realm = 'PBE1' AND queue_id = '1090') OR queue_id = '1100')
            AND game_start <= TIMESTAMP_SUB({{ "TIMESTAMP('" ~ as_of ~ "')" if as_of else "CURRENT_TIMESTAMP()" }}, INTERVAL {{ grace_days | int }} DAY)
    ),

    finished AS (
        SELECT DISTINCT landed.set_num
        FROM landed
        CROSS JOIN released
        WHERE landed.set_num < released.released_set
    )

    SELECT released.released_set, finished.set_num
    FROM released
    LEFT JOIN finished ON TRUE
    ORDER BY finished.set_num
{% endmacro %}
