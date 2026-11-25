SET search_path TO game_schema;
-- Lot B (2026-11-25) : fusion Monstres / Montures. Un TYPE de monstre peut servir de monture (`mountable`) ; il a une rareté,
-- un ou plusieurs modes de déplacement (terrestre / aérien / aquatique) et des bonus de monture (vue, portée, vitesse, portage).
-- La table `mounts` reste le profil utilisé en jeu (character_mounts, marché, kits, déplacement) : elle devient la projection
-- 1:1 d'un type montable (mounts.monster_id), tenue à jour par le trigger sync_mount.

ALTER TABLE monsters ADD COLUMN IF NOT EXISTS mountable  BOOL    NOT NULL DEFAULT FALSE;
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS locomotion TEXT[]  NOT NULL DEFAULT '{land}';
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS rarity     TEXT    NOT NULL DEFAULT 'commun';
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS bonus_see   INT     NOT NULL DEFAULT 0;
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS bonus_range INT     NOT NULL DEFAULT 0;
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS speed       NUMERIC NOT NULL DEFAULT 1;
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS carry       INT     NOT NULL DEFAULT 0;
ALTER TABLE monsters DROP CONSTRAINT IF EXISTS chk_monster_locomotion;
ALTER TABLE monsters ADD CONSTRAINT chk_monster_locomotion CHECK (cardinality(locomotion) >= 1 AND locomotion <@ ARRAY['land','air','water']);
ALTER TABLE monsters DROP CONSTRAINT IF EXISTS chk_monster_rarity;
ALTER TABLE monsters ADD CONSTRAINT chk_monster_rarity CHECK (rarity IN ('commun','rare','epique','legendaire','divin'));

-- terrestrial : la monture peut marcher sur la terre ferme. Historique : « aquatique » = ne quitte pas l'eau (navire).
ALTER TABLE mounts ADD COLUMN IF NOT EXISTS terrestrial BOOL NOT NULL DEFAULT TRUE;
ALTER TABLE mounts ADD COLUMN IF NOT EXISTS monster_id INT UNIQUE REFERENCES monsters(id) ON DELETE CASCADE;
UPDATE mounts SET terrestrial = FALSE WHERE aquatic AND NOT COALESCE(flying, FALSE) AND monster_id IS NULL;

-- Reprise : chaque monture sans type devient un type de monstre montable (nom suffixé si déjà pris).
DO $$
DECLARE r RECORD; nm TEXT; mid INT;
BEGIN
  FOR r IN SELECT * FROM mounts WHERE monster_id IS NULL ORDER BY id LOOP
    nm := r.name;
    IF nm IS NULL OR EXISTS (SELECT 1 FROM monsters WHERE name = nm) THEN nm := COALESCE(r.name, 'Monture') || ' (monture n°' || r.id || ')'; END IF;
    INSERT INTO monsters(name, hp_max, hp_current, recovery, see, strength, agility, energy_max, energy_current, range, armor,
                         mountable, locomotion, bonus_see, bonus_range, speed, carry)
    VALUES (nm, r.hp_max, r.hp_max, r.recovery, 4, r.strength, r.agility, r.energy_max, r.energy_max, 1, r.armor, TRUE,
            array_remove(ARRAY[CASE WHEN r.terrestrial THEN 'land' END, CASE WHEN r.flying THEN 'air' END, CASE WHEN r.aquatic THEN 'water' END], NULL),
            COALESCE(r.bonus_see, 0), COALESCE(r.bonus_range, 0), COALESCE(r.speed, 1), COALESCE(r.carry, 0))
    RETURNING id INTO mid;
    UPDATE mounts SET monster_id = mid WHERE id = r.id;
  END LOOP;
END $$;

-- Projection : tout TYPE montable (pas une instance posée : data.prototype absent) a sa ligne mounts à jour.
-- Décocher « monture » garde la ligne (les montures déjà possédées continuent de fonctionner).
CREATE OR REPLACE FUNCTION sync_mount() RETURNS trigger AS $$
BEGIN
  IF NEW.mountable AND NOT (COALESCE(NEW.data, '{}'::jsonb) ? 'prototype') THEN
    INSERT INTO mounts(monster_id, name, hp_max, armor, energy_max, bonus_see, bonus_range, flying, aquatic, terrestrial, speed, carry, strength, agility, recovery)
    VALUES (NEW.id, NEW.name, COALESCE(NEW.hp_max, 1), COALESCE(NEW.armor, 0), COALESCE(NEW.energy_max, 0), NEW.bonus_see, NEW.bonus_range,
            'air' = ANY(NEW.locomotion), 'water' = ANY(NEW.locomotion), 'land' = ANY(NEW.locomotion), NEW.speed, NEW.carry,
            COALESCE(NEW.strength, 0), COALESCE(NEW.agility, 0), COALESCE(NEW.recovery, 0))
    ON CONFLICT (monster_id) DO UPDATE SET name = EXCLUDED.name, hp_max = EXCLUDED.hp_max, armor = EXCLUDED.armor, energy_max = EXCLUDED.energy_max,
      bonus_see = EXCLUDED.bonus_see, bonus_range = EXCLUDED.bonus_range, flying = EXCLUDED.flying, aquatic = EXCLUDED.aquatic,
      terrestrial = EXCLUDED.terrestrial, speed = EXCLUDED.speed, carry = EXCLUDED.carry, strength = EXCLUDED.strength,
      agility = EXCLUDED.agility, recovery = EXCLUDED.recovery;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_sync_mount ON monsters;
CREATE TRIGGER trg_sync_mount AFTER INSERT OR UPDATE ON monsters FOR EACH ROW EXECUTE FUNCTION sync_mount();
