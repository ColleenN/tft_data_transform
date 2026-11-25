-- Only captures of the Unreal client carry its revision (cdragon_version like
-- 19.1.6018196+rls-19.1.0.6018196). Older Community Dragon captures carry a
-- League build number instead, which isn't comparable, so their revision is
-- NULL.

SELECT
    channel,
    set_number,
    SAFE_CAST(REGEXP_EXTRACT(cdragon_version, r'\+rls-[\d.]*\.(\d+)$') AS INT64) AS revision,
    REGEXP_EXTRACT(cdragon_version, r'^(\d+\.\d+)\.') AS patch,
    cdragon_version,
    captured_at,
    source_object
FROM {{ source('tft_reference', 'units') }}
GROUP BY channel, set_number, cdragon_version, captured_at, source_object
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY channel, set_number, COALESCE(CAST(revision AS STRING), source_object)
    ORDER BY captured_at DESC
) = 1
