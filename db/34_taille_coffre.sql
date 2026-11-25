SET search_path TO game_schema;
-- 1) Taille des monstres (1 à 3) : montée, une créature élève son cavalier de `size` niveaux (+1 vision / +1 portée par niveau).
--    Les anciens bonus de vision / portée des montures ne s'appliquent plus (seules les capacités passives de leurs sorts comptent).
-- 2) Coffre : taille de départ et capacité maximale réglées par capitale (buildings.data.chestStart / chestMax, admin Bâtiments).
-- Idempotent.
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS size INT NOT NULL DEFAULT 1;
DO $$ BEGIN ALTER TABLE monsters ADD CONSTRAINT chk_monster_size CHECK (size BETWEEN 1 AND 3); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
