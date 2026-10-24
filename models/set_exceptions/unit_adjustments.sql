-- Every set exception's unit adjustments in one table. Aggregation models join
-- this once and never reference an individual exception or set.
--
-- To add an exception: build it in its own folder under models/set_exceptions/,
-- make its final model match the contract in _set_exceptions.yml, and add that
-- model's name to the list below. (The list is explicit because dbt needs every
-- ref() known when it parses the project, so it can't discover models by tag.)

{% set exceptions = [
    'set14_viego_ghosts',
] %}

{% for exception in exceptions %}
SELECT match_id, puuid, character_id, tier, unit_instance_index, adjustment, reason
FROM {{ ref(exception) }}
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
