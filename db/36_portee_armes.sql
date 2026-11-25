SET search_path TO game_schema;
-- Portée des objets (2026-11-26) : portée d'une arme (1 = corps à corps) ; arme à distance : pleine puissance jusqu'à N cases,
-- puis les dégâts baissent jusqu'à 50 % à la portée max. La distance à la cible compte l'écart de hauteur (Pythagore, back/src/game/reach.ts).
-- Idempotent.
ALTER TABLE items ADD COLUMN IF NOT EXISTS reach INT NOT NULL DEFAULT 1;
ALTER TABLE items ADD COLUMN IF NOT EXISTS full_power_at INT;
ALTER TABLE items DROP CONSTRAINT IF EXISTS chk_item_reach;
ALTER TABLE items ADD CONSTRAINT chk_item_reach CHECK (reach BETWEEN 1 AND 20 AND (full_power_at IS NULL OR (full_power_at >= 1 AND full_power_at < reach)));
