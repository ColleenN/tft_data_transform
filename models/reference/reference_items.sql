{% set type_columns = {
    'artifact': 'num_artifacts',
    'radiant': 'num_radiants',
    'support': 'num_supports',
    'emblem': 'num_emblems',
    'component': 'num_components',
    'tg_item': 'num_tg_items',
    'tac_item': 'num_tac_items',
} %}
{% set component_columns = {
    'sword': 'num_swords',
    'vest': 'num_vests',
    'pan': 'num_pans',
    'belt': 'num_belts',
    'rod': 'num_rods',
    'cloak': 'num_cloaks',
    'bow': 'num_bows',
    'gloves': 'num_gloves',
    'spatula': 'num_spats',
    'tear': 'num_tears',
} %}

WITH types AS (
    SELECT
        source_object, set_number, item_api_name,
        {% for item_type, column in type_columns.items() %}
        COUNTIF(item_type = '{{ item_type }}') AS {{ column }}{{ ',' if not loop.last }}
        {% endfor %}
    FROM {{ source('tft_reference', 'item_types') }}
    GROUP BY source_object, set_number, item_api_name
),

components AS (
    SELECT
        source_object, set_number, item_api_name,
        {% for component, column in component_columns.items() %}
        SUM(IF(component = '{{ component }}', count, 0)) AS {{ column }}{{ ',' if not loop.last }}
        {% endfor %}
    FROM {{ source('tft_reference', 'item_components') }}
    GROUP BY source_object, set_number, item_api_name
)

SELECT
    items.source_object,
    items.set_number,
    items.item_name,
    items.item_api_name,
    TO_JSON_STRING(items.effects) AS effects,
    items.trait_granted,
    items.unique,
    items.num_craftables,
    {% for column in type_columns.values() | list + component_columns.values() | list %}
    IFNULL({{ column }}, 0) AS {{ column }}{{ ',' if not loop.last }}
    {% endfor %}
FROM            {{ source('tft_reference', 'items') }} AS items
    LEFT JOIN   types USING (source_object, set_number, item_api_name)
    LEFT JOIN   components USING (source_object, set_number, item_api_name)
