-- Units per reference capture, with hand-maintained corrections from
-- seed_unit_overrides applied on top. Downstream models use this instead of
-- the reference table, so no model needs a set-specific literal.
--
-- Overrides are keyed by set, so each applies to every capture of its set. A
-- FULL OUTER JOIN keeps units that exist only in the overrides (for example
-- unlockable units the reference data doesn't list).

WITH generated AS (
    SELECT source_object, set_number AS set_num, api_name, name, cost, role, shop_unit
    FROM {{ source('tft_reference', 'units') }}
),

captures AS (
    SELECT DISTINCT source_object, set_num
    FROM generated
),

overrides AS (
    SELECT captures.source_object, overrides.*
    FROM            {{ ref('seed_unit_overrides') }} AS overrides
        INNER JOIN  captures USING (set_num)
)

SELECT
    COALESCE(generated.source_object, overrides.source_object) AS source_object,
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
    -- Board slots the unit occupies: 1 for most units, 0 or 2 for some.
    COALESCE(overrides.num_board_slots, 1) AS num_board_slots
FROM generated
    FULL OUTER JOIN overrides
        ON generated.source_object = overrides.source_object
        AND generated.set_num = overrides.set_num
        AND generated.api_name = overrides.api_name
