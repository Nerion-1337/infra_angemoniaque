SET search_path TO game_schema;
-- Foi et Pactes réglables en admin (décision du 2026-11-26). Rejouable.
-- FOI (game_config.faith, JSON) : XP et or par heure pour le dieu, par tranche de `followersStep` fidèles ; prières : `prayers`
-- par `prayerPeriodH` heures ; bénédictions : par caractéristique, valeur max, durée max (h) et coût en énergie divine pour
-- ce maximum (le dieu choisit valeur et durée ≥ 1 h ; coût au prorata, arrondi au supérieur). Bonus temporaire (temp_buffs).
-- PACTES : compositions (`pact_tiers`) choisies par l'Ange / le Démon pour chaque pacte : XP / or par heure pour lui, % des
-- caractéristiques (game_config.pact.stats) transféré à l'Humain à l'activation, durée du bonus, délai avant réactivation.
-- Nombre de pactes par rang (`specializations.max_pacts`, NULL = règle par défaut).

CREATE TABLE IF NOT EXISTS pact_tiers (
  id          SERIAL PRIMARY KEY,
  name        TEXT    NOT NULL UNIQUE,
  xp_hour     INT     NOT NULL DEFAULT 0 CHECK (xp_hour >= 0),
  gold_hour   INT     NOT NULL DEFAULT 0 CHECK (gold_hour >= 0),
  percent     INT     NOT NULL CHECK (percent BETWEEN 1 AND 100),
  duration_h  NUMERIC NOT NULL DEFAULT 1 CHECK (duration_h >= 1),
  cooldown_h  NUMERIC NOT NULL DEFAULT 0 CHECK (cooldown_h >= 0),
  sort        INT     NOT NULL DEFAULT 0
);
INSERT INTO pact_tiers(name, xp_hour, gold_hour, percent, duration_h, cooldown_h, sort)
SELECT * FROM (VALUES ('Faible', 1, 1, 10, 1, 0, 1), ('Moyen', 3, 3, 20, 1, 0, 2), ('Fort', 5, 5, 30, 1, 0, 3)) v
WHERE NOT EXISTS (SELECT 1 FROM pact_tiers);

ALTER TABLE pacts ADD COLUMN IF NOT EXISTS tier_id  INT REFERENCES pact_tiers(id) ON DELETE SET NULL;
ALTER TABLE pacts ADD COLUMN IF NOT EXISTS ready_at TIMESTAMPTZ;   -- prochaine activation possible (fin du bonus + délai)
UPDATE pacts SET tier_id = (SELECT id FROM pact_tiers ORDER BY sort, id LIMIT 1) WHERE tier_id IS NULL;
DROP INDEX IF EXISTS uq_pact_human;   -- le nombre de pactes d'un Humain se règle désormais par rang

ALTER TABLE specializations ADD COLUMN IF NOT EXISTS max_pacts INT CHECK (max_pacts >= 0);

CREATE TABLE IF NOT EXISTS faith_prayers (
  id           SERIAL PRIMARY KEY,
  faith_id     INT NOT NULL REFERENCES faiths(id) ON DELETE CASCADE,
  character_id INT NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  stat         TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS faith_prayers_char ON faith_prayers(character_id, created_at);
UPDATE faiths SET request_choice = NULL WHERE request_choice = 'heal';   -- « soin » n'est pas une caractéristique

-- Réglages par défaut proches de l'ancien comportement (+2 XP / or par fidèle, une prière toutes les 72 h, 5 ÉD).
INSERT INTO game_config(key, value) VALUES
  ('faith', '{"followersStep":1,"xpHour":2,"goldHour":2,"prayers":1,"prayerPeriodH":72,"blessings":{"strength":{"max":5,"maxH":24,"cost":5},"agility":{"max":5,"maxH":24,"cost":5},"hp_max":{"max":20,"maxH":24,"cost":5},"recovery":{"max":3,"maxH":24,"cost":5}}}'),
  ('pact',  '{"stats":["strength","agility"]}')
ON CONFLICT (key) DO NOTHING;
