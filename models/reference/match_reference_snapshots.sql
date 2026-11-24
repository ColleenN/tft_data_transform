WITH matches AS (
    SELECT
        match_id,
        tft_set_number,
        TIMESTAMP(server_side_game_start) AS game_start,
        IF(server_realm_code = 'PBE1', 'pbe', 'live') AS channel,
        IF(server_realm_code = 'PBE1', 'pbe-global', CONCAT('live-', server_realm_code)) AS version_set
    FROM {{ ref('unique_matches') }}
),

deploys AS (
    SELECT version_set, SAFE_CAST(revision AS INT64) AS revision, captured_at
    FROM {{ source('tft_reference', 'client_deploys') }}
    WHERE platform = 'windows' AND artifact_type = 'client'
),

match_revisions AS (
    SELECT matches.*, deploys.revision
    FROM            matches
        LEFT JOIN   deploys
            ON deploys.version_set = matches.version_set
            AND deploys.captured_at <= matches.game_start
    QUALIFY ROW_NUMBER() OVER (PARTITION BY matches.match_id ORDER BY deploys.captured_at DESC) = 1
),

snapshots AS (
    SELECT channel, set_number, revision, source_object
    FROM {{ ref('reference_snapshots') }}
    WHERE revision IS NOT NULL
),

latest_at_or_before AS (
    SELECT match_revisions.match_id, snapshots.revision, snapshots.source_object
    FROM            match_revisions
        INNER JOIN  snapshots
            ON snapshots.channel = match_revisions.channel
            AND snapshots.set_number = match_revisions.tft_set_number
            AND snapshots.revision <= match_revisions.revision
    QUALIFY ROW_NUMBER() OVER (PARTITION BY match_revisions.match_id ORDER BY snapshots.revision DESC) = 1
),

-- PBE matches played before the set's first snapshot (including those from
-- before deploys were tracked) use that first snapshot, since the client
-- can't be re-extracted for builds it no longer has.
oldest AS (
    SELECT channel, set_number, revision, source_object
    FROM snapshots
    QUALIFY ROW_NUMBER() OVER (PARTITION BY channel, set_number ORDER BY revision) = 1
)

SELECT
    matches.match_id,
    matches.tft_set_number,
    matches.channel,
    matches.game_start,
    matches.revision AS client_revision,
    COALESCE(found.revision, oldest.revision) AS reference_revision,
    COALESCE(found.source_object, oldest.source_object) AS reference_source_object,
    CASE
        WHEN found.revision = matches.revision THEN 'exact'
        WHEN found.revision IS NOT NULL THEN 'earlier_build'
        WHEN oldest.revision IS NOT NULL THEN 'oldest_snapshot'
    END AS reference_match
FROM            match_revisions AS matches
    LEFT JOIN   latest_at_or_before AS found USING (match_id)
    LEFT JOIN   oldest
        ON found.match_id IS NULL
        AND matches.channel = 'pbe'
        AND oldest.channel = matches.channel
        AND oldest.set_number = matches.tft_set_number
