SET search_path TO game_schema;
-- Étape 2 — Races : zone d'apparition et limites de personnages ; horloge du monde persistante.
--  - races.spawn_map_id / spawn_x / spawn_y / spawn_radius : où naissent les nouveaux personnages de la race
--    (case libre tirée dans le carré centre ± rayon) ; spawn_map_id NULL = capitale de la race (comportement historique).
--  - races.max_per_account : personnages max de cette race par compte (3 = règle historique ; NULL = illimité).
--  - races.max_total : population max de la race, tous comptes confondus (NULL = illimité).
--    Le compte administrateur n'est soumis à aucune de ces limites (ni à la règle « une seule race par compte »).
--  - game_clock.last_tick_at : instant du dernier tick horaire appliqué. Le serveur rattrape les heures écoulées
--    (y compris pendant un arrêt) en rejouant un tick par heure pleine, puis avance l'horloge d'autant.
-- Idempotent.

ALTER TABLE races ADD COLUMN IF NOT EXISTS spawn_map_id INT REFERENCES maps(id) ON DELETE SET NULL;
ALTER TABLE races ADD COLUMN IF NOT EXISTS spawn_x INT CHECK (spawn_x >= 0);
ALTER TABLE races ADD COLUMN IF NOT EXISTS spawn_y INT CHECK (spawn_y >= 0);
ALTER TABLE races ADD COLUMN IF NOT EXISTS spawn_radius INT NOT NULL DEFAULT 4 CHECK (spawn_radius BETWEEN 0 AND 100);
ALTER TABLE races ADD COLUMN IF NOT EXISTS max_per_account INT DEFAULT 3 CHECK (max_per_account IS NULL OR max_per_account >= 0);
ALTER TABLE races ADD COLUMN IF NOT EXISTS max_total INT CHECK (max_total IS NULL OR max_total >= 0);

CREATE TABLE IF NOT EXISTS game_clock (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  last_tick_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO game_clock(id, last_tick_at) VALUES (1, now()) ON CONFLICT (id) DO NOTHING;

-- Garde-fou en base (trigger historique : 3 personnages max, même race) aligné sur les règles réglables :
-- limite par compte = races.max_per_account de la race (NULL = illimité), population = races.max_total,
-- et AUCUNE limite pour un compte administrateur (accounts.role = 'admin').
CREATE OR REPLACE FUNCTION chk_char_limit() RETURNS trigger AS $$
DECLARE mpa INT := 3; mt INT := NULL;   -- race absente de la table races : règle historique (3 par compte)
BEGIN
  IF (SELECT role FROM accounts WHERE id=NEW.account_id) = 'admin' THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM characters WHERE account_id=NEW.account_id AND race<>NEW.race) THEN RAISE EXCEPTION 'Même race obligatoire'; END IF;
  IF EXISTS (SELECT 1 FROM races WHERE key=NEW.race) THEN SELECT max_per_account, max_total INTO mpa, mt FROM races WHERE key=NEW.race; END IF;
  IF mpa IS NOT NULL AND (SELECT count(*) FROM characters WHERE account_id=NEW.account_id) >= mpa THEN
    RAISE EXCEPTION '% personnages max', mpa; END IF;
  IF mt IS NOT NULL AND (SELECT count(*) FROM characters WHERE race=NEW.race) >= mt THEN
    RAISE EXCEPTION 'Population maximale atteinte'; END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
