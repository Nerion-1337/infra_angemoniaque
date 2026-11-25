SET search_path TO game_schema;
-- 1) Équipement : plus d'emplacement « arc / flèches ». Un arc est une ARME À DEUX MAINS (`items.two_handed`, réglable en admin
--    pour toute arme) : posée en main principale, elle occupe aussi l'autre main (ni bouclier ni seconde arme).
--    Les types d'objets créés en admin avec les noms de parties du corps des monstres (« mains », « tete »…) sont ramenés aux
--    types d'objets du jeu (weapon, head…) : sinon aucun emplacement de l'inventaire ne les acceptait.
-- 2) Amélioration de carte (Hôtel de ville) : `characters.map_upgrade` ; prix réglable en admin (game_config.map_upgrade_price).
-- Idempotent.
ALTER TABLE items ADD COLUMN IF NOT EXISTS two_handed BOOL NOT NULL DEFAULT FALSE;
UPDATE items SET two_handed = TRUE WHERE NOT two_handed AND (slot = 'bow' OR data->>'hands' = '2');
UPDATE items SET slot = CASE slot WHEN 'bow' THEN 'weapon' WHEN 'mains' THEN 'weapon' WHEN 'tete' THEN 'head' WHEN 'torse' THEN 'chest'
  WHEN 'pieds' THEN 'foot' WHEN 'collier' THEN 'amulet' WHEN 'bague' THEN 'ring' ELSE slot END
  WHERE slot IN ('bow', 'mains', 'tete', 'torse', 'pieds', 'collier', 'bague');
-- Arc déjà équipé : passe en main principale si les deux mains sont libres, sinon retourne au sac.
UPDATE character_items ci SET equipped_slot = CASE WHEN NOT EXISTS (SELECT 1 FROM character_items o WHERE o.character_id = ci.character_id AND o.equipped_slot IN ('weapon_main', 'weapon_off'))
  THEN 'weapon_main' ELSE NULL END WHERE equipped_slot = 'bow';
ALTER TABLE characters ADD COLUMN IF NOT EXISTS map_upgrade BOOL NOT NULL DEFAULT FALSE;
INSERT INTO game_config (key, value) VALUES ('map_upgrade_price', '500') ON CONFLICT (key) DO NOTHING;
