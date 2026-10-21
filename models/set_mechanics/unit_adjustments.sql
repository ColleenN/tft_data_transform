-- Every set mechanic's unit adjustments in one table. Aggregation models join
-- this once and never reference an individual mechanic or set.
--
-- To add a mechanic: build it in its own folder under models/set_mechanics/,
-- make its final model match the contract in _set_mechanics.yml, and add that
-- model's name to the list below. (The list is explicit because dbt needs every
-- ref() known when it parses the project, so it can't discover models by tag.)

{% set mechanics = [
    'set14_viego_ghosts',
] %}

{% for mechanic in mechanics %}
SELECT match_id, puuid, character_id, tier, unit_instance_index, adjustment, reason
FROM {{ ref(mechanic) }}
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
