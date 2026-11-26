{% set board_columns = [
    'num_unit_slots', 'num_units', 'num_unit_slots_used', 'total_board_unit_cost', 'overall_gold_value',
    'num_items', 'num_craftables', 'num_artifacts', 'num_radiants', 'num_supports', 'num_emblems', 'num_tac_items',
    'num_swords', 'num_rods', 'num_bows', 'num_gloves', 'num_tears',
    'num_vests', 'num_cloaks', 'num_belts', 'num_spats', 'num_pans',
] %}

WITH boards AS (
    SELECT
        annotated.match_id,
        annotated.puuid,
        annotated.tft_set_number,
        builds.channel,
        builds.patch,
        annotated.last_round,
        CAST(annotated.level AS FLOAT64) AS level,
        CAST(annotated.gold_left AS FLOAT64) AS gold_left,
        {% for column in board_columns %}
        CAST(aggregated.{{ column }} AS FLOAT64) AS {{ column }}{{ ',' if not loop.last }}
        {% endfor %}
    FROM            {{ ref('seed_annotated_boards') }} AS annotated
        INNER JOIN  {{ ref('aggregations_boards') }} AS aggregated USING (match_id, puuid)
        INNER JOIN  {{ ref('match_reference_snapshots') }} AS builds USING (match_id)
)

SELECT match_id, puuid, tft_set_number, channel, patch, last_round, resource, value
FROM boards
UNPIVOT INCLUDE NULLS (value FOR resource IN (
    level, gold_left,
    {% for column in board_columns %}
    {{ column }}{{ ',' if not loop.last }}
    {% endfor %}
))
