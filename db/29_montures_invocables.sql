SET search_path TO game_schema;
-- 2026-11-25 : une monture possédée peut être MONTÉE (énergie de déplacement prise sur elle) ou simplement INVOQUÉE à pied
-- (invocation contrôlable qui reprend ses PV / son énergie) ; elle peut être équipée sur les parties du corps de son type.
ALTER TABLE character_mounts ADD COLUMN IF NOT EXISTS id SERIAL;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'character_mounts_pkey') THEN ALTER TABLE character_mounts ADD CONSTRAINT character_mounts_pkey PRIMARY KEY (id); END IF;
END $$;
-- Invocation : type de monstre d'origine (capacités) et monture possédée qu'elle représente (invoquée à pied).
ALTER TABLE summons ADD COLUMN IF NOT EXISTS monster_id INT REFERENCES monsters(id) ON DELETE SET NULL;
ALTER TABLE summons ADD COLUMN IF NOT EXISTS char_mount_id INT UNIQUE REFERENCES character_mounts(id) ON DELETE CASCADE;
-- Équipement d'une monture possédée : l'objet quitte le sac du joueur, y revient au retrait (slot ∈ parties équipables du type).
CREATE TABLE IF NOT EXISTS mount_equips (
  char_mount_id INT  NOT NULL REFERENCES character_mounts(id) ON DELETE CASCADE,
  slot          TEXT NOT NULL CHECK (slot IN ('mains','tete','torse','pieds','collier','bracelet','bague')),
  item_id       INT  NOT NULL REFERENCES items(id),
  PRIMARY KEY (char_mount_id, slot)
);
-- Monture invoquée à pied qui disparaît (renvoyée, tuée, expirée) : ses PV et son énergie reviennent sur la monture possédée
-- (tuée → 0 PV : elle doit se régénérer avant d'être montée ou réinvoquée).
CREATE OR REPLACE FUNCTION summon_back_to_mount() RETURNS trigger AS $$
BEGIN
  IF OLD.char_mount_id IS NOT NULL THEN
    UPDATE character_mounts SET hp_current = GREATEST(0, OLD.hp_current), energy_current = GREATEST(0, OLD.energy_current) WHERE id = OLD.char_mount_id;
  END IF;
  RETURN OLD;
END $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_summon_back_to_mount ON summons;
CREATE TRIGGER trg_summon_back_to_mount BEFORE DELETE ON summons FOR EACH ROW EXECUTE FUNCTION summon_back_to_mount();
