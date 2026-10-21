-- ⚠ GÉNÉRÉ par tools/gen_human_map.py — Monde des Hommes : portails, retours, Minotaure, brûlure du volcan.
SET search_path TO game_schema;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS burn_until TIMESTAMPTZ;   -- brûlure du volcan (10 dégâts / heure)
-- Portail d'origine déplacé sur la nouvelle carte (nord-ouest)
UPDATE positions SET coord_x=51, coord_y=44 WHERE building_id=(SELECT id FROM buildings WHERE name='Le Seuil des Deux Voiles');
-- Trois nouveaux portails (4 au total) : tous exigent un Artefact
INSERT INTO buildings(name,kind,invulnerable,data) SELECT v.n,'door',true,v.d::jsonb FROM (VALUES
 ('Portail de Givre','{"requires": "artefact", "to": [2, 40, 56]}'),
 ('Porte des Dunes','{"requires": "artefact", "to": [2, 140, 31]}'),
 ('Passage des Marais','{"requires": "artefact", "to": [2, 167, 163]}')) v(n,d)
WHERE NOT EXISTS (SELECT 1 FROM buildings b WHERE b.name=v.n);
INSERT INTO positions(map_id,coord_x,coord_y,building_id) SELECT 1,v.x,v.y,b.id FROM (VALUES
 ('Portail de Givre',138,22),
 ('Porte des Dunes',142,152),
 ('Passage des Marais',45,154)) v(n,x,y) JOIN buildings b ON b.name=v.n
WHERE NOT EXISTS (SELECT 1 FROM positions q WHERE q.building_id=b.id);
-- Les retours des mondes Ange/Démon arrivent dans la zone sacrée de l'Hôtel de ville
UPDATE buildings SET data=jsonb_set(data,'{to}','[1,100,92]') WHERE name='Brèche de Soufre';
UPDATE buildings SET data=jsonb_set(data,'{to}','[1,100,108]') WHERE name='L’Arche de Grâce';
-- Le Minotaure garde désormais le grand arbre
UPDATE positions SET coord_x=146, coord_y=68 WHERE monsters_id=(SELECT id FROM monsters WHERE name='Minotaure');
