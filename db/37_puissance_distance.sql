SET search_path TO game_schema;
-- Armes à grande portée (2026-11-26) : puissance de départ à la case 1 (power_start %), 100 % à la case `full_power_at`,
-- puissance restante à la dernière case de portée (power_end %) ; linéaire entre ces points. Dégâts arrondis au supérieur.
-- Reprise : les armes déjà réglées gardent l'ancien comportement (100 % jusqu'à X, 50 % au bout). Idempotent.
ALTER TABLE items ADD COLUMN IF NOT EXISTS power_start INT NOT NULL DEFAULT 100;
ALTER TABLE items ADD COLUMN IF NOT EXISTS power_end INT NOT NULL DEFAULT 50;
ALTER TABLE items DROP CONSTRAINT IF EXISTS chk_item_reach;
ALTER TABLE items ADD CONSTRAINT chk_item_reach CHECK (reach BETWEEN 1 AND 20 AND (full_power_at IS NULL OR (full_power_at >= 1 AND full_power_at <= reach))
  AND power_start BETWEEN 0 AND 100 AND power_end BETWEEN 0 AND 100);
