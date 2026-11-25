{# Under --empty, source() renders as an empty subquery, which would leave no
   trait columns to pivot; look the traits up in the table itself. #}
{% set trait_tiers = source('tft_reference', 'trait_tiers') %}
{% set trait_list = dbt_utils.get_column_values(
    table=api.Relation.create(database=trait_tiers.database, schema=trait_tiers.schema, identifier=trait_tiers.identifier),
    column='api_name',
    where="NOT type = 'LEGENDARY' AND set_number = " ~ var('current_set'),
) %}

SELECT
    match_id, puuid,
    {{ dbt_utils.pivot('name', trait_list, agg='max', then_value='tier_current') }}
FROM
    {{ ref('unpacked_traits') }}
GROUP BY match_id, puuid
