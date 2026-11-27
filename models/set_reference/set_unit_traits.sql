-- Units' innate traits per reference capture. num_trait_units counts the
-- units holding each trait in that capture, so unique (single-unit) traits
-- can be told apart from traits units share.

SELECT
    source_object,
    set_number AS set_num,
    api_name,
    trait_api_name,
    trait_name,
    COUNT(DISTINCT api_name) OVER (PARTITION BY source_object, set_number, trait_api_name) AS num_trait_units
FROM {{ source('tft_reference', 'unit_innate_traits') }}
