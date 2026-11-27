SET search_path TO game_schema;
-- Pactes : nombre maximal d'attributions d'une composition par Ange / Démon (`pact_tiers.max_assign`, NULL = illimité) ;
-- date du dernier changement de composition d'un pacte (`pacts.tier_changed_at`) : un changement au plus toutes les 48 h.
-- Améliorations : paliers de coût en nombre libre (`stat_cost_rules.multis`, un multiplicateur par palier), repris des
-- trois colonnes historiques multi_1..3 (gardées, plus lues). Idempotent.
ALTER TABLE pact_tiers ADD COLUMN IF NOT EXISTS max_assign INT CHECK (max_assign IS NULL OR max_assign >= 1);
ALTER TABLE pacts      ADD COLUMN IF NOT EXISTS tier_changed_at TIMESTAMPTZ;
ALTER TABLE stat_cost_rules ADD COLUMN IF NOT EXISTS multis NUMERIC[];
UPDATE stat_cost_rules SET multis = ARRAY[COALESCE(multi_1, 1), COALESCE(multi_2, 2), COALESCE(multi_3, 3)] WHERE multis IS NULL;
