-- ⚠ GÉNÉRÉ par tools/gen_angel_demon_map.py — Monde des Anges et des Démons : carte 300x300 (démons à l'ouest, anges à l'est, Voile au centre).
SET search_path TO game_schema;
UPDATE maps SET width=300, height=300 WHERE id=2;
-- Capitales : une par moitié
UPDATE positions SET map_id=2, coord_x=75, coord_y=150 WHERE building_id=(SELECT id FROM buildings WHERE name='Bastion Infernal');
UPDATE positions SET map_id=2, coord_x=225, coord_y=150 WHERE building_id=(SELECT id FROM buildings WHERE name='Sanctuaire de la Providence');
-- Portes vers le monde des Hommes : Brèche de Soufre (démons), Arche de Grâce (anges)
UPDATE positions SET map_id=2, coord_x=100, coord_y=122 WHERE building_id=(SELECT id FROM buildings WHERE name='Brèche de Soufre');
UPDATE positions SET map_id=2, coord_x=189, coord_y=133 WHERE building_id=(SELECT id FROM buildings WHERE name='L’Arche de Grâce');
-- Arrivées des 4 portails du monde des Hommes (Voile nord, moitié angélique, moitié démoniaque, Voile sud)
UPDATE buildings SET data=jsonb_set(data,'{to}','[2,149,94]') WHERE name='Le Seuil des Deux Voiles';
UPDATE buildings SET data=jsonb_set(data,'{to}','[2,252,75]') WHERE name='Portail de Givre';
UPDATE buildings SET data=jsonb_set(data,'{to}','[2,53,244]') WHERE name='Porte des Dunes';
UPDATE buildings SET data=jsonb_set(data,'{to}','[2,150,215]') WHERE name='Passage des Marais';
-- Gardiens des objets divins : le Balrog près du volcan démoniaque, le Léviathan dans le lac de l'Ascension
UPDATE positions SET coord_x=67, coord_y=74 WHERE monsters_id=(SELECT id FROM monsters WHERE name='Balrog');
UPDATE positions SET coord_x=230, coord_y=205 WHERE monsters_id=(SELECT id FROM monsters WHERE name='Léviathan');
