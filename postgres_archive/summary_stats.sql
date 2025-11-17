--All of these assume the input data set consists of
--Game ID + Player ID + Placement
{% macro select_unit_avps(
    table1_name,
    star_levels=False,
    items='none'
) %}
-- items arg expected to be one of "none", "counts", "include", "build",

WITH expanded AS
(
    SELECT unit_info.*, {{ table1_name }}.placement
    FROM
        {{ table1_name }}
        {{ join_on_board_id(table1_name, ref('annotated_unit_entries'), 'unit_info') }}
    WHERE is_ghost = False
),
consolidated AS
(
    SELECT expanded.match_id, expanded.puuid, expanded.placement, api_name, true_unit_cost
    {% if star_levels %}, tier as star_level{% endif %}
    {% if items == 'counts' %}, num_items as item_count{% endif %}


    FROM            {{ ref('seed_units') }} all_units
        LEFT JOIN   expanded
            ON all_units.api_name = expanded.character_id
    WHERE all_units.shop_unit
    GROUP BY
        expanded.match_id, expanded.puuid, expanded.placement, api_name, true_unit_cost
        {% if star_levels %}, tier{% endif %}
        {% if items == 'counts' %}, num_items{% endif %}
)

SELECT api_name, true_unit_cost,
       {% if star_levels %}star_level, {% endif %}
       {% if items == 'counts' %}item_count, {% endif %}
       COUNT(*) AS sample_size, AVG(placement), stddev_samp(placement)
FROM consolidated
GROUP BY api_name, true_unit_cost
    {% if star_levels %}, star_level{% endif %}
    {% if items == 'counts' %}, item_count{% endif %}

{% endmacro %}