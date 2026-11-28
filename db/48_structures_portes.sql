SET search_path TO game_schema;
-- Lot du 2026-11-28 : structures, portes, Royaume des Morts, pactes des demi-dieux. Idempotent.
-- 1. Structures : zone sans combat (`peace_radius`) et zone sans construction (`nobuild_radius`) autour d'elles.
-- 2. Réapparition réglée sur chaque structure (comme les monstres) : recréée ou non, délai, conditions (éléments limités) ;
--    une structure détruite garde sa dernière case (`home`) et sa date de destruction (`destroyed_at`).
-- 3. Portes : monde de la porte (`realm`) et monde vers lequel elle mène (`leads_to`) ; activation par objets divins,
--    `open_h_per_item` heures par objet, ouverte jusqu'à `open_until`. Les portes des Hommes, des Démons et des Anges deviennent
--    destructibles (1000 points de structure, reconstruites 48 h après leur destruction).
-- 4. Royaume des Morts agrandi de 50 % (150 × 150) ; porte au centre qui ramène chaque joueur dans son monde.
-- 5. Pactes des demi-dieux : compositions propres (`pact_tiers.realm = 'demigod'`), rang autorisé à proposer (`pact_patron`).
-- 6. Règles générales : perte à la mort (`death_loss_pct`), bonus des portes ouvertes (`gate_bonus`).
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS peace_radius INT NOT NULL DEFAULT 0 CHECK (peace_radius BETWEEN 0 AND 100);
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS nobuild_radius INT NOT NULL DEFAULT 0 CHECK (nobuild_radius BETWEEN 0 AND 100);
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS respawn BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS respawn_delay_h NUMERIC NOT NULL DEFAULT 0 CHECK (respawn_delay_h >= 0);
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS respawn_limits JSONB NOT NULL DEFAULT '[]';
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS home JSONB;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS destroyed_at TIMESTAMPTZ;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS leads_to TEXT CHECK (leads_to IN ('human', 'demon', 'angel'));
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS open_h_per_item NUMERIC NOT NULL DEFAULT 24 CHECK (open_h_per_item > 0);
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS open_until TIMESTAMPTZ;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='buildings' AND column_name='realm') THEN
    ALTER TABLE buildings ADD COLUMN realm TEXT CHECK (realm IN ('human', 'demon', 'angel', 'dead'));
    UPDATE buildings SET realm='human', leads_to='demon' WHERE kind='door' AND name IN ('Le Seuil des Deux Voiles', 'Porte des Dunes');
    UPDATE buildings SET realm='human', leads_to='angel' WHERE kind='door' AND name IN ('Portail de Givre', 'Passage des Marais');
    UPDATE buildings SET realm='demon', leads_to='human' WHERE kind='door' AND name='Brèche de Soufre';
    UPDATE buildings SET realm='angel', leads_to='human' WHERE kind='door' AND name='L’Arche de Grâce';
    UPDATE buildings SET invulnerable=false, structure=GREATEST(structure, 1000), respawn=true, respawn_delay_h=48 WHERE kind='door' AND realm IS NOT NULL;
  END IF;
END $$;
-- Royaume des Morts : 150 × 150 et sa porte centrale (invulnérable)
UPDATE maps SET width=150, height=150 WHERE id=3 AND width=100;
INSERT INTO buildings(name, kind, invulnerable, data, realm) SELECT 'Porte des Âmes', 'door', true, '{}', 'dead'
WHERE NOT EXISTS (SELECT 1 FROM buildings WHERE kind='door' AND realm='dead');
INSERT INTO positions(map_id, coord_x, coord_y, building_id) SELECT 3, 75, 75, b.id FROM buildings b
WHERE b.kind='door' AND b.realm='dead' AND b.destroyed_at IS NULL AND NOT EXISTS (SELECT 1 FROM positions p WHERE p.building_id=b.id)
  AND NOT EXISTS (SELECT 1 FROM positions p WHERE p.map_id=3 AND p.coord_x=75 AND p.coord_y=75 AND p.item_id IS NULL);
-- Pactes des demi-dieux
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='pact_tiers' AND column_name='realm') THEN
    ALTER TABLE pact_tiers ADD COLUMN realm TEXT NOT NULL DEFAULT 'ethereal' CHECK (realm IN ('ethereal', 'demigod'));
    ALTER TABLE pact_tiers DROP CONSTRAINT IF EXISTS pact_tiers_name_key;
    ALTER TABLE pact_tiers ADD CONSTRAINT pact_tiers_realm_name_key UNIQUE (realm, name);
    INSERT INTO pact_tiers(name, xp_hour, gold_hour, percent, duration_h, cooldown_h, sort, max_assign, realm)
      SELECT name, xp_hour, gold_hour, percent, duration_h, cooldown_h, sort, max_assign, 'demigod' FROM pact_tiers WHERE realm='ethereal';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='specializations' AND column_name='pact_patron') THEN
    ALTER TABLE specializations ADD COLUMN pact_patron BOOLEAN NOT NULL DEFAULT false;
    UPDATE specializations SET pact_patron=true WHERE race='human' AND lower(name)='demi-dieu';
  END IF;
END $$;
INSERT INTO game_config(key, value) VALUES ('death_loss_pct', '25') ON CONFLICT (key) DO NOTHING;
INSERT INTO game_config(key, value) VALUES ('gate_bonus', '{"demon":{},"angel":{}}') ON CONFLICT (key) DO NOTHING;
