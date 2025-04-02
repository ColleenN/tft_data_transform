SELECT 	units.match_id, units.puuid, units.character_id, units.tier, units.unit_instance_index,
		CASE WHEN items.tg_item IS NULL THEN False ELSE items.tg_item END AS tg_item,
		SUM(CASE WHEN craftable = True THEN 1 ELSE 0 END) AS num_craftables,
		SUM(CASE WHEN artifact = True THEN 1 ELSE 0 END) AS num_artifacts,
		SUM(CASE WHEN radiant = True THEN 1 ELSE 0 END) AS num_radiants,
		SUM(CASE WHEN support = True THEN 1 ELSE 0 END) AS num_supports,
		SUM(CASE WHEN emblem = True THEN 1 ELSE 0 END) AS num_emblems,
		SUM(CASE WHEN tac_item = True THEN 1 ELSE 0 END) AS num_tac_items,

		SUM(CASE WHEN swords IS NULL THEN 0 ELSE swords END) AS num_swords,
		SUM(CASE WHEN rods IS NULL THEN 0 ELSE rods END) AS num_rods,
		SUM(CASE WHEN bows IS NULL THEN 0 ELSE bows END) AS num_bows,
		SUM(CASE WHEN gloves IS NULL THEN 0 ELSE gloves END) AS num_gloves,
		SUM(CASE WHEN tears IS NULL THEN 0 ELSE tears END) AS num_tears,
		SUM(CASE WHEN vests IS NULL THEN 0 ELSE vests END) AS num_vests,
		SUM(CASE WHEN cloaks IS NULL THEN 0 ELSE cloaks END) AS num_cloaks,
		SUM(CASE WHEN belts IS NULL THEN 0 ELSE belts END) AS num_belts,
		SUM(CASE WHEN spats IS NULL THEN 0 ELSE spats END) AS num_spats,
		SUM(CASE WHEN pans IS NULL THEN 0 ELSE pans END) AS num_pans
FROM
				{{ ref('board_unit_data') }} units
	LEFT JOIN 	{{ ref('annotated_unit_item_entries') }} items
		ON
			units.match_id = items.match_id AND
			units.puuid = items.puuid AND
			units.character_id = items.character_id AND
			units.tier = items.tier AND
			units.unit_instance_index = items.unit_instance_index
GROUP BY units.match_id,
         units.puuid,
         units.character_id,
         units.tier,
         units.unit_instance_index,
         items.tg_item