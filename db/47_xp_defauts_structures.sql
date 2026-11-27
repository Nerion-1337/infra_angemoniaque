SET search_path TO game_schema;
-- Corrections du 2026-11-27 :
-- 1. XP de combat et entraînement : valeur GÉNÉRALE (game_config.combat_xp) appliquée à chaque race et chaque rang ; la valeur
--    d'un rang ne s'applique que si elle est précisée (NULL = valeur générale). Les 0 posés par défaut en migration 46 deviennent NULL.
-- 2. Structures attaquables (sauf invulnérables) : points de structure courants (`buildings.structure_current`, NULL = intacte,
--    = `structure`) ; XP gagnée par le joueur à chaque coup porté contre la structure (`buildings.xp_hit`).
-- Idempotent.
DO $$ DECLARE c TEXT; BEGIN
  FOREACH c IN ARRAY ARRAY['xp_hit_player', 'xp_dodge', 'train_energy', 'train_xp'] LOOP
    EXECUTE format('ALTER TABLE specializations ALTER COLUMN %I DROP NOT NULL, ALTER COLUMN %I DROP DEFAULT', c, c);
    EXECUTE format('UPDATE specializations SET %I = NULL WHERE %I = 0', c, c);
  END LOOP; END $$;
INSERT INTO game_config(key, value) VALUES ('combat_xp', '{"xp_hit_player":0,"xp_dodge":0,"train_energy":0,"train_xp":0}') ON CONFLICT (key) DO NOTHING;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS xp_hit INT NOT NULL DEFAULT 0 CHECK (xp_hit >= 0);
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS structure_current INT CHECK (structure_current IS NULL OR structure_current >= 0);
