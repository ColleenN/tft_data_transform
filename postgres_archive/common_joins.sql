{% macro join_on_board_id(table1, table2, table2_alias="") %}
    {% if table2_alias %}
    LEFT JOIN {{ table2 }} AS {{ table2_alias }}
    	ON {{ table1 }}.match_id = {{ table2_alias }}.match_id
		AND {{ table1 }}.puuid = {{ table2_alias }}.puuid
    {% else %}
    LEFT JOIN {{ table2 }}
		ON {{ table1 }}.match_id = {{ table2 }}.match_id
		AND {{ table1 }}.puuid = {{ table2 }}.puuid
    {% endif %}
{% endmacro %}



