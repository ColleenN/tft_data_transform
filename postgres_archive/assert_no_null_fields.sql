SELECT *
FROM dbt.annotated_boards
WHERE
    num_swords IS NULL OR
    num_rods IS NULL OR
    num_bows IS NULL OR
    num_gloves IS NULL OR
    num_tears IS NULL OR
    num_vests IS NULL OR
    num_cloaks IS NULL OR
    num_belts IS NULL OR
    num_spats IS NULL OR
    num_pans IS NULL OR
    num_craftables IS NULL OR
    num_artifacts IS NULL OR
    num_radiants IS NULL OR
    num_supports IS NULL OR
    num_emblems IS NULL OR
    num_tac_items IS NULL