SET search_path TO game_schema;
-- Fin des MONTURES (décision du 2026-11-26) : plus de montures possédées, d'équipement de monture, de navire ni de catalogue
-- de montures. À la place, un sort INVOQUE un monstre ; si son type est « montable » (monsters.mountable), son propriétaire peut
-- MONTER dessus (characters.riding_summon_id) une fois invoqué, ou dès le lancer du sort. Les montures possédées sont supprimées
-- (choix de l'humain : pas de conversion).
-- Délais (en heures, décimales permises) : spells.cooldown_h = délai avant de relancer un sort ; monsters.resummon_delay_h =
-- délai avant de relancer le sort qui l'a invoqué quand l'invocation MEURT (spell_cooldowns, posé par trigger). Idempotent.

-- 1. Monte d'une invocation et délais
ALTER TABLE summons    ADD COLUMN IF NOT EXISTS spell_id INT REFERENCES spells(id) ON DELETE SET NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS riding_summon_id INT UNIQUE REFERENCES summons(id) ON DELETE SET NULL;
ALTER TABLE spells     ADD COLUMN IF NOT EXISTS cooldown_h NUMERIC NOT NULL DEFAULT 0 CHECK (cooldown_h >= 0);
ALTER TABLE monsters   ADD COLUMN IF NOT EXISTS resummon_delay_h NUMERIC NOT NULL DEFAULT 0 CHECK (resummon_delay_h >= 0);
CREATE TABLE IF NOT EXISTS spell_cooldowns (
  character_id INT NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  spell_id     INT NOT NULL REFERENCES spells(id) ON DELETE CASCADE,
  ready_at     TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (character_id, spell_id)
);

-- Mort d'une invocation (supprimée à 0 PV : combatlib.applyDamage) : le sort qui l'a invoquée attend le délai de son type.
CREATE OR REPLACE FUNCTION summon_death_cooldown() RETURNS trigger AS $$
DECLARE d NUMERIC;
BEGIN
  IF OLD.hp_current <= 0 AND OLD.spell_id IS NOT NULL AND OLD.monster_id IS NOT NULL THEN
    SELECT resummon_delay_h INTO d FROM monsters WHERE id = OLD.monster_id;
    IF COALESCE(d, 0) > 0 THEN
      INSERT INTO spell_cooldowns(character_id, spell_id, ready_at) VALUES (OLD.owner_id, OLD.spell_id, now() + make_interval(secs => d * 3600))
      ON CONFLICT (character_id, spell_id) DO UPDATE SET ready_at = GREATEST(spell_cooldowns.ready_at, EXCLUDED.ready_at);
    END IF;
  END IF;
  RETURN OLD;
END $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_summon_death_cooldown ON summons;
CREATE TRIGGER trg_summon_death_cooldown BEFORE DELETE ON summons FOR EACH ROW EXECUTE FUNCTION summon_death_cooldown();

-- 2. Sorts qui donnaient une monture : ils invoquent désormais le monstre (refId était déjà l'id du type de monstre).
UPDATE spells SET effects = jsonb_set(effects, '{summon,kind}', '"monster"')
 WHERE effects->'summon'->>'kind' = 'mount';

-- 3. Suppression de tout ce qui touche aux montures
DROP TRIGGER IF EXISTS trg_summon_back_to_mount ON summons;
DROP FUNCTION IF EXISTS summon_back_to_mount();
DROP TRIGGER IF EXISTS trg_sync_mount ON monsters;
DROP FUNCTION IF EXISTS sync_mount();
ALTER TABLE summons DROP COLUMN IF EXISTS char_mount_id;
DROP TABLE IF EXISTS mount_equips;
DROP TABLE IF EXISTS character_mounts;
DELETE FROM entity_spells WHERE kind = 'mount';
ALTER TABLE entity_spells DROP CONSTRAINT IF EXISTS entity_spells_kind_check;
ALTER TABLE entity_spells ADD CONSTRAINT entity_spells_kind_check CHECK (kind IN ('item', 'building'));
DELETE FROM spell_summons WHERE kind = 'mount';
ALTER TABLE spell_summons DROP CONSTRAINT IF EXISTS spell_summons_kind_check;
ALTER TABLE spell_summons ADD CONSTRAINT spell_summons_kind_check CHECK (kind IN ('monster', 'item', 'building'));
DELETE FROM market_listings WHERE kind = 'mount';
UPDATE races SET start_kit = start_kit - 'mounts' WHERE start_kit ? 'mounts';
DO $$ BEGIN   -- rejouable : la colonne n'existe plus au 2e passage
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='positions' AND column_name='mount_id') THEN
    DELETE FROM positions WHERE mount_id IS NOT NULL;
  END IF;
END $$;
ALTER TABLE positions DROP CONSTRAINT IF EXISTS chk_exclusive_entity;
ALTER TABLE positions DROP COLUMN IF EXISTS mount_id;
ALTER TABLE positions ADD CONSTRAINT chk_exclusive_entity CHECK (num_nonnulls(character_id, monsters_id, building_id, item_id, summon_id) = 1);
DROP TABLE IF EXISTS mounts;
-- Champs propres aux montures, inutilisés depuis : vitesse, portage, anciens bonus de vue / portée ; « monture » des kinds autorisés.
ALTER TABLE monsters DROP COLUMN IF EXISTS speed, DROP COLUMN IF EXISTS carry, DROP COLUMN IF EXISTS bonus_see, DROP COLUMN IF EXISTS bonus_range;
-- Parchemin de navire (il donnait la monture « Navire ») : retiré des joueurs, du marché et du catalogue.
DELETE FROM character_items  WHERE item_id IN (SELECT id FROM items WHERE slot = 'scroll' AND data->>'kind' = 'ship');
DELETE FROM market_listings  WHERE kind = 'item' AND ref_id IN (SELECT id FROM items WHERE slot = 'scroll' AND data->>'kind' = 'ship');
DELETE FROM items            WHERE slot = 'scroll' AND data->>'kind' = 'ship';
UPDATE tile_types SET description = 'Infranchissable à pied : il faut monter une invocation volante ou aquatique.' WHERE kind = 'deep' AND description LIKE '%navire%';
UPDATE spells SET usable_by = usable_by - 'monture' WHERE usable_by ? 'monture';
UPDATE items  SET usable_by = usable_by - 'monture' WHERE usable_by ? 'monture';
