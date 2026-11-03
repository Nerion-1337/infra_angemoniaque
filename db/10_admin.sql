-- Étape 2, phase 1 — Espace administrateur : rôles, races/rangs dynamiques, règles
-- transverses (coûts/caps/modificateurs), config globale, audit. Les tables des phases
-- suivantes (butin/spawn/cases/sauvegardes) sont créées ici pour ne migrer qu'une fois.
SET search_path TO game_schema;

-- 1) Rôles des comptes (player/mod/admin) ; les comptes is_admin héritent de 'admin'
ALTER TABLE accounts ADD COLUMN role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player','mod','admin'));
UPDATE accounts SET role = 'admin' WHERE is_admin;

-- 2) Sanctions & réputation (module modération, phase 4)
ALTER TABLE characters ADD COLUMN level INT NOT NULL DEFAULT 1,
  ADD COLUMN reputation INT NOT NULL DEFAULT 0,
  ADD COLUMN muted_until TIMESTAMPTZ,
  ADD COLUMN banned_until TIMESTAMPTZ,
  ADD COLUMN banned_permanent BOOL NOT NULL DEFAULT FALSE;

-- 3) Races dynamiques (les 4 classiques sont seedées) ; le CHECK de specializations devient une FK
CREATE TABLE races (
  id SERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  base_stats JSONB NOT NULL DEFAULT '{}',
  color TEXT,
  active BOOL NOT NULL DEFAULT TRUE
);
INSERT INTO races (key, name, base_stats) VALUES
 ('human',    'Humain',    '{"hp_max":100,"energy_max":50,"recovery":5,"see":5,"strength":5,"agility":5}'),
 ('demon',    'Démon',     '{"hp_max":200,"energy_max":65,"recovery":8,"see":8,"strength":10,"agility":10}'),
 ('angel',    'Ange',      '{"hp_max":200,"energy_max":65,"recovery":8,"see":8,"strength":10,"agility":10}'),
 ('nephilim', 'Néphilim',  '{"hp_max":400,"energy_max":90,"recovery":12,"see":15,"strength":15,"agility":15}');
ALTER TABLE specializations DROP CONSTRAINT IF EXISTS specializations_race_check;
ALTER TABLE specializations ADD CONSTRAINT fk_spec_race FOREIGN KEY (race) REFERENCES races(key);
-- Arbre des rangs : paliers avec prérequis et multiplicateurs de caractéristiques
ALTER TABLE specializations ADD COLUMN prereq_xp INT,
  ADD COLUMN multipliers JSONB NOT NULL DEFAULT '{}',
  ADD COLUMN evolution TEXT;

-- 4) Règles transverses applicables à monstres/objets/montures/bâtiments/races/divins
--    (kind : 'monster','item','mount','building','race','divine')
CREATE TABLE entity_costs (
  id SERIAL PRIMARY KEY,
  kind TEXT NOT NULL, ref_id INT NOT NULL,
  resource TEXT NOT NULL, qty INT NOT NULL DEFAULT 0,
  UNIQUE (kind, ref_id, resource)
);
CREATE TABLE entity_caps (
  id SERIAL PRIMARY KEY,
  kind TEXT NOT NULL, ref_id INT NOT NULL,
  scope TEXT NOT NULL CHECK (scope IN ('global','per_player','per_zone')),
  value INT NOT NULL DEFAULT 1,
  UNIQUE (kind, ref_id, scope)
);
CREATE TABLE entity_modifiers (
  id SERIAL PRIMARY KEY,
  kind TEXT NOT NULL, ref_id INT NOT NULL,
  stat TEXT NOT NULL, value NUMERIC NOT NULL,
  is_percent BOOL NOT NULL DEFAULT FALSE,
  effect_key TEXT, duration_h INT, is_active BOOL NOT NULL DEFAULT FALSE,
  description TEXT,
  UNIQUE (kind, ref_id, stat, effect_key)
);

-- 5) Caractéristiques demandées par l'espace admin (durabilité, vitesse/portage,
--    structure/taille/prérequis, comportement de monstre)
ALTER TABLE items     ADD COLUMN durability INT;
ALTER TABLE mounts    ADD COLUMN speed NUMERIC NOT NULL DEFAULT 1,
  ADD COLUMN carry INT NOT NULL DEFAULT 0;
ALTER TABLE buildings ADD COLUMN structure INT NOT NULL DEFAULT 0,
  ADD COLUMN size INT NOT NULL DEFAULT 1,
  ADD COLUMN prerequisites JSONB NOT NULL DEFAULT '{}';
ALTER TABLE monsters  ADD COLUMN data JSONB NOT NULL DEFAULT '{}';

-- 6) Tables de butin & règles d'apparition (phase 2)
CREATE TABLE monster_loot (
  id SERIAL PRIMARY KEY,
  monster_id INT NOT NULL REFERENCES monsters(id) ON DELETE CASCADE,
  item_id INT REFERENCES items(id) ON DELETE SET NULL,
  divine_id INT REFERENCES divine_items(id) ON DELETE SET NULL,
  drop_rate NUMERIC NOT NULL CHECK (drop_rate >= 0 AND drop_rate <= 100),
  qty_min INT NOT NULL DEFAULT 1,
  qty_max INT NOT NULL DEFAULT 1,
  CHECK (item_id IS NOT NULL OR divine_id IS NOT NULL)
);
CREATE TABLE spawn_rules (
  id SERIAL PRIMARY KEY,
  monster_id INT NOT NULL REFERENCES monsters(id) ON DELETE CASCADE,
  map_id INT NOT NULL REFERENCES maps(id),
  x_min INT, y_min INT, x_max INT, y_max INT,
  max_instances INT NOT NULL DEFAULT 1,
  interval_h INT NOT NULL DEFAULT 1,
  conditions JSONB NOT NULL DEFAULT '{}'
);

-- 7) Cases & événements (phase 3) : overrides posés sur la grille générée
CREATE TABLE tile_overrides (
  map_id INT NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  x INT NOT NULL, y INT NOT NULL,
  kind TEXT, cost INT, resource TEXT, resource_amount INT,
  regen_per_hour NUMERIC,
  effects JSONB NOT NULL DEFAULT '{}',
  UNIQUE (map_id, x, y)
);
CREATE TABLE map_events (
  id SERIAL PRIMARY KEY,
  map_id INT REFERENCES maps(id),
  x INT, y INT, kind TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}',
  active BOOL NOT NULL DEFAULT TRUE,
  expires_at TIMESTAMPTZ,
  created_by INT REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8) Config globale (multiplicateurs live-ops), audit d'administration, sauvegardes de contenu
CREATE TABLE game_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_by INT REFERENCES accounts(id),
  updated_at TIMESTAMPTZ DEFAULT now()
);
INSERT INTO game_config (key, value) VALUES
 ('xp_rate', '1'), ('drop_rate', '1'), ('gather_speed', '1'),
 ('move_speed', '1'), ('regen_rate', '1'), ('maintenance', 'false'),
 ('divine_caps', '{"relique":4,"arcane":4,"artefact":5}');

CREATE TABLE admin_audit (
  id BIGSERIAL PRIMARY KEY,
  actor_id INT REFERENCES accounts(id),
  action TEXT NOT NULL,
  target TEXT, target_id INT,
  before JSONB, after JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_audit_created ON admin_audit(created_at DESC);

CREATE TABLE content_backups (
  id SERIAL PRIMARY KEY,
  label TEXT,
  payload JSONB NOT NULL,
  created_by INT REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
