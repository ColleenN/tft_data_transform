--All of these assume the input data set consists of
--Game ID + Player ID + Placement
{% macro select_unit_avps(table1_name) %}

WITH expanded AS
(
    SELECT unit_info.*, {{ table1_name }}.placement
    FROM
        {{ table1_name }}
        {{ join_on_board_id(table1_name, ref('annotated_unit_entries'), 'unit_info') }}
    WHERE is_ghost = False AND shop_unit = 1
),
consolidated AS
(
    SELECT expanded.match_id, expanded.puuid, expanded.placement, api_name
    FROM            expanded
        LEFT JOIN   {{ ref('seed_units') }} all_units
            ON all_units.api_name = expanded.character_id
    GROUP BY
        expanded.match_id, expanded.puuid, expanded.placement, api_name
)

SELECT api_name, AVG(placement)
FROM consolidated
GROUP BY api_name

{% endmacro %}