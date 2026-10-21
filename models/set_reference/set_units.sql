-- Unit reference data for the current set: generated values from seed_units,
-- with hand-maintained corrections from seed_unit_overrides applied on top.
-- Downstream models use this instead of seed_units, so no model needs a
-- set-specific literal.
--
-- A FULL OUTER JOIN keeps units that exist only in the overrides (for example
-- unlockable units the generated seed doesn't list).
--
-- TODO: once tft_set_info_tools writes a set_num column into seed_units, take
-- set_num from the seed instead of var('current_set').

WITH generated AS (
    SELECT {{ var('current_set') }} AS set_num, *
    FROM {{ ref('seed_units') }}
),

overrides AS (
    SELECT *
    FROM {{ ref('seed_unit_overrides') }}
    WHERE set_num = {{ var('current_set') }}
)

SELECT
    COALESCE(generated.set_num, overrides.set_num) AS set_num,
    COALESCE(generated.api_name, overrides.api_name) AS api_name,
    generated.name,
    generated.cost,
    generated.role,
    IFNULL(generated.shop_unit, FALSE) AS shop_unit,
    -- Cost as shown in the shop.
    COALESCE(overrides.shop_gold_cost, generated.cost) AS shop_gold_cost,
    -- Gold value of a 1-star copy: only units bought from the shop (or given
    -- a cost override) carry gold value.
    COALESCE(
        overrides.shop_gold_cost,
        CASE WHEN generated.shop_unit THEN generated.cost ELSE 0 END
    ) AS one_star_gold_value,
    COALESCE(overrides.takes_board_slot, TRUE) AS takes_board_slot
FROM generated
    FULL OUTER JOIN overrides
        ON generated.set_num = overrides.set_num
        AND generated.api_name = overrides.api_name
