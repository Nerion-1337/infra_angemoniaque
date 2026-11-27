SET search_path TO game_schema;
-- Lot du 2026-11-27.
-- 1. Couche d'une case : un élément AU SOL et un élément DANS LES AIRS peuvent partager une case. `positions.air` (vrai pour un monstre
--    ou une invocation dont le type vole — locomotion avec 'air' —, et pour un personnage monté sur une invocation volante) est
--    tenu à jour par triggers ; l'unicité de case (uq_cell) devient (carte, x, y, couche). Les bâtiments gardent leur index à part.
-- 2. Arme à distance (`items.ranged`) : sa portée s'ajoute à la portée du personnage (hauteur comprise) ; une arme de mêlée n'a que
--    sa propre portée (lance 2, épée 1).
-- 3. XP de combat et entraînement, par rang (`specializations`) : XP quand le joueur frappe un autre joueur, XP du défenseur quand il
--    esquive, coût en énergie et XP d'un entraînement. XP au coup porté contre un type de monstre (`monsters.xp_hit`).
-- Idempotent.
ALTER TABLE positions ADD COLUMN IF NOT EXISTS air BOOLEAN NOT NULL DEFAULT false;
CREATE OR REPLACE FUNCTION pos_air_of(p_monster INT, p_summon INT, p_char INT) RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  SELECT COALESCE(CASE
    WHEN p_monster IS NOT NULL THEN (SELECT 'air' = ANY(m.locomotion) FROM monsters m WHERE m.id = p_monster)
    WHEN p_summon  IS NOT NULL THEN (SELECT 'air' = ANY(t.locomotion) FROM summons s JOIN monsters t ON t.id = s.monster_id WHERE s.id = p_summon)
    WHEN p_char    IS NOT NULL THEN (SELECT 'air' = ANY(t.locomotion) FROM characters c JOIN summons s ON s.id = c.riding_summon_id JOIN monsters t ON t.id = s.monster_id WHERE c.id = p_char)
  END, false) $$;
CREATE OR REPLACE FUNCTION trg_pos_air() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.air := NEW.building_id IS NULL AND NEW.item_id IS NULL AND pos_air_of(NEW.monsters_id, NEW.summon_id, NEW.character_id); RETURN NEW; END $$;
DROP TRIGGER IF EXISTS pos_air ON positions;
CREATE TRIGGER pos_air BEFORE INSERT OR UPDATE ON positions FOR EACH ROW EXECUTE FUNCTION trg_pos_air();
-- Monter / descendre d'une invocation volante, ou changer le déplacement d'un type : couche recalculée (le trigger ci-dessus s'en charge).
CREATE OR REPLACE FUNCTION trg_pos_air_refresh_char() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN UPDATE positions SET air = air WHERE character_id = NEW.id; RETURN NEW; END $$;
DROP TRIGGER IF EXISTS pos_air_char ON characters;
CREATE TRIGGER pos_air_char AFTER UPDATE OF riding_summon_id ON characters FOR EACH ROW WHEN (OLD.riding_summon_id IS DISTINCT FROM NEW.riding_summon_id) EXECUTE FUNCTION trg_pos_air_refresh_char();
CREATE OR REPLACE FUNCTION trg_pos_air_refresh_monster() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE positions SET air = air WHERE monsters_id = NEW.id
     OR summon_id IN (SELECT id FROM summons WHERE monster_id = NEW.id)
     OR character_id IN (SELECT c.id FROM characters c JOIN summons s ON s.id = c.riding_summon_id WHERE s.monster_id = NEW.id);
  RETURN NEW; END $$;
DROP TRIGGER IF EXISTS pos_air_monster ON monsters;
CREATE TRIGGER pos_air_monster AFTER UPDATE OF locomotion ON monsters FOR EACH ROW WHEN (OLD.locomotion IS DISTINCT FROM NEW.locomotion) EXECUTE FUNCTION trg_pos_air_refresh_monster();
DROP INDEX IF EXISTS uq_cell;
UPDATE positions SET air = air;   -- calcul initial (trigger)
CREATE UNIQUE INDEX uq_cell ON positions(map_id, coord_x, coord_y, air) WHERE item_id IS NULL AND building_id IS NULL;

ALTER TABLE items ADD COLUMN IF NOT EXISTS ranged BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE specializations ADD COLUMN IF NOT EXISTS xp_hit_player INT NOT NULL DEFAULT 0 CHECK (xp_hit_player >= 0);
ALTER TABLE specializations ADD COLUMN IF NOT EXISTS xp_dodge      INT NOT NULL DEFAULT 0 CHECK (xp_dodge >= 0);
ALTER TABLE specializations ADD COLUMN IF NOT EXISTS train_energy  INT NOT NULL DEFAULT 0 CHECK (train_energy >= 0);
ALTER TABLE specializations ADD COLUMN IF NOT EXISTS train_xp      INT NOT NULL DEFAULT 0 CHECK (train_xp >= 0);
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS xp_hit INT NOT NULL DEFAULT 0 CHECK (xp_hit >= 0);
