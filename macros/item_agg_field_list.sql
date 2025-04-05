{% macro select_item_component_counts() %}
    CASE WHEN num_swords IS NULL THEN 0 ELSE num_swords END,
	CASE WHEN num_rods IS NULL THEN 0 ELSE num_rods END,
	CASE WHEN num_bows IS NULL THEN 0 ELSE num_bows END,
	CASE WHEN num_gloves IS NULL THEN 0 ELSE num_gloves END,
	CASE WHEN num_tears IS NULL THEN 0 ELSE num_tears END,
	CASE WHEN num_vests IS NULL THEN 0 ELSE num_vests END,
	CASE WHEN num_cloaks IS NULL THEN 0 ELSE num_cloaks END,
	CASE WHEN num_belts IS NULL THEN 0 ELSE num_belts END,
	CASE WHEN num_spats IS NULL THEN 0 ELSE num_spats END,
	CASE WHEN num_pans IS NULL THEN 0 ELSE num_pans END
{% endmacro %}

{% macro select_item_component_sums() %}
    SUM(CASE WHEN num_swords IS NULL THEN 0 ELSE num_swords END) AS num_swords,
    SUM(CASE WHEN num_rods IS NULL THEN 0 ELSE num_rods END) AS num_rods,
    SUM(CASE WHEN num_bows IS NULL THEN 0 ELSE num_bows END) AS num_bows,
    SUM(CASE WHEN num_gloves IS NULL THEN 0 ELSE num_gloves END) AS num_gloves,
    SUM(CASE WHEN num_tears IS NULL THEN 0 ELSE num_tears END) AS num_tears,
    SUM(CASE WHEN num_vests IS NULL THEN 0 ELSE num_vests END) AS num_vests,
    SUM(CASE WHEN num_cloaks IS NULL THEN 0 ELSE num_cloaks END) AS num_cloaks,
    SUM(CASE WHEN num_belts IS NULL THEN 0 ELSE num_belts END) AS num_belts,
    SUM(CASE WHEN num_spats IS NULL THEN 0 ELSE num_spats END) AS num_spats,
    SUM(CASE WHEN num_pans IS NULL THEN 0 ELSE num_pans END) AS num_pans
{% endmacro %}

{% macro select_item_category_counts() %}
    CASE WHEN num_craftables IS NULL THEN 0 ELSE num_craftables END,
    CASE WHEN num_artifacts IS NULL THEN 0 ELSE num_artifacts END,
    CASE WHEN num_radiants IS NULL THEN 0 ELSE num_radiants END,
    CASE WHEN num_supports IS NULL THEN 0 ELSE num_supports END,
    CASE WHEN num_emblems IS NULL THEN 0 ELSE num_emblems END,
    CASE WHEN num_tac_items IS NULL THEN 0 ELSE num_tac_items END
{% endmacro %}

{% macro select_item_category_sums() %}
    SUM(CASE WHEN num_craftables IS NULL THEN 0 ELSE num_craftables END) AS num_craftables,
    SUM(CASE WHEN num_artifacts IS NULL THEN 0 ELSE num_artifacts END) AS num_artifacts,
    SUM(CASE WHEN num_radiants IS NULL THEN 0 ELSE num_radiants END) AS num_radiants,
    SUM(CASE WHEN num_supports IS NULL THEN 0 ELSE num_supports END) AS num_supports,
    SUM(CASE WHEN num_emblems IS NULL THEN 0 ELSE num_emblems END) AS num_emblems,
    SUM(CASE WHEN num_tac_items IS NULL THEN 0 ELSE num_tac_items END) AS num_tac_items
{% endmacro %}