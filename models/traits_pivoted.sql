{% set trait_list=dbt_utils.get_column_values(table=ref('seed_trait_tiers'), column='api_name', where="NOT type = 'LEGENDARY'") %}

SELECT
    match_id, puuid,
    {{ dbt_utils.pivot('name', trait_list, agg='max', then_value='tier_current') }}
FROM 
    {{ ref('unpacked_traits') }}
GROUP BY match_id, puuid
