WITH rows AS ({{ select_unit_avps(ref('base_board_data'), star_levels=True, items='none') }})

SELECT *
FROM {{ ref('seed_units') }} unit_base
    LEFT JOIN rows
        ON unit_base.api_name = rows.api_name
WHERE shop_unit = True AND rows.api_name IS NULL
