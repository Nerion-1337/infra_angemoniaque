SET search_path TO game_schema;
-- Lot du 2026-11-25 : réapparition par monstre posé, objet divin porté, équipement des monstres type personnage, XP.
-- 1) Réapparition : réglée sur CHAQUE monstre posé (colonnes respawn / reincarnate_delay_h / respawn_limits de sa ligne) et non
--    plus sur le type ; les instances existantes reprennent les réglages de leur type (et l'ancien délai data.reincarnate_h).
UPDATE monsters i SET respawn = p.respawn, respawn_limits = p.respawn_limits,
  reincarnate_delay_h = COALESCE((i.data->>'reincarnate_h')::int, i.reincarnate_delay_h)
  FROM monsters p WHERE p.id = (i.data->>'prototype')::int AND p.id <> i.id;
-- 2) Objet divin porté : un monstre gardien porte UN exemplaire de sa famille à la fois ; tué, il le donne au tueur et revient
--    (après son délai) avec un nouvel exemplaire, tant que la famille n'est pas complète chez les joueurs (plafond de la famille).
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS divine_family TEXT REFERENCES divine_families(key) ON UPDATE CASCADE ON DELETE SET NULL;
UPDATE monsters m SET divine_family = (SELECT min(kind) FROM divine_items WHERE guardian_monster_id = m.id)
  WHERE divine_family IS NULL AND EXISTS (SELECT 1 FROM divine_items WHERE guardian_monster_id = m.id AND holder_character_id IS NULL);
-- Un seul exemplaire gardé par monstre : les autres redeviennent libres (repris un par un aux réapparitions).
UPDATE divine_items d SET guardian_monster_id = NULL WHERE holder_character_id IS NULL AND guardian_monster_id IS NOT NULL
  AND id <> (SELECT min(id) FROM divine_items o WHERE o.guardian_monster_id = d.guardian_monster_id AND o.holder_character_id IS NULL);
-- 3) Équipement des monstres : mêmes emplacements que les personnages (deux armes, deux bracelets, deux bagues).
ALTER TABLE monster_equips DROP CONSTRAINT IF EXISTS monster_equips_slot_check;
ALTER TABLE monster_slots DROP CONSTRAINT IF EXISTS monster_slots_slot_check;
UPDATE monster_equips SET slot = CASE slot WHEN 'mains' THEN 'weapon_main' WHEN 'tete' THEN 'head' WHEN 'torse' THEN 'chest' WHEN 'pieds' THEN 'foot'
  WHEN 'collier' THEN 'amulet' WHEN 'bracelet' THEN 'bracelet_l' WHEN 'bague' THEN 'ring_l' ELSE slot END;
INSERT INTO monster_slots(monster_id, slot) SELECT monster_id, v.x FROM monster_slots, LATERAL (VALUES ('weapon_main'), ('weapon_off')) v(x) WHERE slot = 'mains' ON CONFLICT DO NOTHING;
INSERT INTO monster_slots(monster_id, slot) SELECT monster_id, v.x FROM monster_slots, LATERAL (VALUES ('bracelet_l'), ('bracelet_r')) v(x) WHERE slot = 'bracelet' ON CONFLICT DO NOTHING;
INSERT INTO monster_slots(monster_id, slot) SELECT monster_id, v.x FROM monster_slots, LATERAL (VALUES ('ring_l'), ('ring_r')) v(x) WHERE slot = 'bague' ON CONFLICT DO NOTHING;
INSERT INTO monster_slots(monster_id, slot) SELECT monster_id, CASE slot WHEN 'tete' THEN 'head' WHEN 'torse' THEN 'chest' WHEN 'pieds' THEN 'foot' ELSE 'amulet' END
  FROM monster_slots WHERE slot IN ('tete', 'torse', 'pieds', 'collier') ON CONFLICT DO NOTHING;
DELETE FROM monster_slots WHERE slot IN ('mains', 'bracelet', 'bague', 'tete', 'torse', 'pieds', 'collier');
ALTER TABLE monster_slots ADD CONSTRAINT monster_slots_slot_check CHECK (slot IN ('weapon_main','weapon_off','head','chest','foot','amulet','ring_l','ring_r','bracelet_l','bracelet_r'));
ALTER TABLE monster_equips ADD CONSTRAINT monster_equips_slot_check CHECK (slot IN ('weapon_main','weapon_off','head','chest','foot','amulet','ring_l','ring_r','bracelet_l','bracelet_r'));
-- Équipement des créatures possédées (montures invoquables, migration 29) : mêmes emplacements.
ALTER TABLE mount_equips DROP CONSTRAINT IF EXISTS mount_equips_slot_check;
UPDATE mount_equips SET slot = CASE slot WHEN 'mains' THEN 'weapon_main' WHEN 'tete' THEN 'head' WHEN 'torse' THEN 'chest' WHEN 'pieds' THEN 'foot'
  WHEN 'collier' THEN 'amulet' WHEN 'bracelet' THEN 'bracelet_l' WHEN 'bague' THEN 'ring_l' ELSE slot END;
ALTER TABLE mount_equips ADD CONSTRAINT mount_equips_slot_check CHECK (slot IN ('weapon_main','weapon_off','head','chest','foot','amulet','ring_l','ring_r','bracelet_l','bracelet_r'));
-- Une pièce par emplacement (deux armes identiques possibles) au lieu d'une ligne par objet.
ALTER TABLE monster_equips DROP CONSTRAINT IF EXISTS monster_equips_monster_id_item_id_key;
DELETE FROM monster_equips e WHERE id <> (SELECT min(id) FROM monster_equips o WHERE o.monster_id = e.monster_id AND o.slot = e.slot);
CREATE UNIQUE INDEX IF NOT EXISTS monster_equips_slot_uq ON monster_equips(monster_id, slot);
-- 4) XP : récompense ponctuelle du monstre au tueur (remplace l'XP/h, inutilisée pour un monstre) et rang du monstre ;
--    XP gagnée en utilisant un objet (coup porté avec une arme, parchemin utilisé) ou un sort ;
--    bonus / malus selon l'écart de rang entre le personnage et sa cible (Races & rangs, game_config.xp_rank_diff : écart → %).
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS xp_reward INT NOT NULL DEFAULT 0 CHECK (xp_reward >= 0);
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS rank INT NOT NULL DEFAULT 1 CHECK (rank BETWEEN 1 AND 50);
UPDATE monsters SET xp_reward = gain_xp_hour WHERE xp_reward = 0 AND COALESCE(gain_xp_hour, 0) > 0;
ALTER TABLE items ADD COLUMN IF NOT EXISTS xp_use INT NOT NULL DEFAULT 0 CHECK (xp_use >= 0);
ALTER TABLE spells ADD COLUMN IF NOT EXISTS xp_use INT NOT NULL DEFAULT 0 CHECK (xp_use >= 0);
INSERT INTO game_config(key, value) VALUES ('xp_rank_diff', '{"-2":50,"-1":75,"0":100,"1":125,"2":150}') ON CONFLICT (key) DO NOTHING;
