{#
    Archives every set that a newer set has replaced, for a scheduled job:

        dbt run-operation archive_finished_sets --args '{dry_run: true}'
        dbt run-operation archive_finished_sets

    A set counts as released once it has been in the live channel's reference
    data (loaded from mirrored CDragon snapshots) for grace_days. Match data
    for a set is no use until its reference data exists, so the reference
    data decides rather than the matches. The grace period covers a set
    showing up in live data before launch and leaves time for late matches
    of the old set to land.

    Every set number below the newest released set that still has rows in
    the landing tables goes to archive_set, oldest first. archive_set still
    refuses var('current_set'), so the job fails on the old set until
    current_set is bumped.

    landing_dataset, reference_dataset and as_of (which replaces the current
    time) are for the integration tests.
#}

{% macro archive_finished_sets(grace_days=var('archive_grace_days', 14), archive_dataset=var('archive_dataset', 'match_data_archive'), dry_run=false, landing_dataset=none, reference_dataset=none, as_of=none) %}
    {% set tables = [] %}
    {% for table_name in ['tft_player_match_detail', 'apex_ranked_ladder_match_detail', 'normal_ranked_ladder_match_detail'] %}
        {% if landing_dataset %}
            {% do tables.append(api.Relation.create(database=target.database, schema=landing_dataset, identifier=table_name)) %}
        {% else %}
            {% do tables.append(source('riot_tap', table_name)) %}
        {% endif %}
    {% endfor %}
    {% if reference_dataset %}
        {% set units = api.Relation.create(database=target.database, schema=reference_dataset, identifier='units') %}
    {% else %}
        {% set units = source('tft_reference', 'units') %}
    {% endif %}

    {% set result = run_query(archive_finished_sets_sql(tables, units, grace_days, as_of)) %}
    {% set released = result.rows[0]['released_set'] if result.rows else none %}
    {% set finished = result.columns['set_num'].values() | reject('none') | list %}

    {% if released is none %}
        {{ log("No set has been in live reference data for " ~ grace_days ~ " days; nothing to archive", info=true) }}
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
{% macro archive_finished_sets_sql(tables, units, grace_days, as_of) %}
    WITH released AS (
        SELECT MAX(set_number) AS released_set
        FROM (
            SELECT set_number, MIN(captured_at) AS first_seen
            FROM {{ units }}
            WHERE channel = 'live'
            GROUP BY set_number
        )
        WHERE first_seen <= TIMESTAMP_SUB({{ "TIMESTAMP('" ~ as_of ~ "')" if as_of else "CURRENT_TIMESTAMP()" }}, INTERVAL {{ grace_days | int }} DAY)
    ),

    landed AS (
        {% for t in tables %}
        SELECT SAFE_CAST(JSON_VALUE(data, "$.info.tft_set_number") AS INT64) AS set_num
        FROM {{ t }}
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
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
