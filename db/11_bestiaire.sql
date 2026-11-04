SET search_path TO game_schema;
-- Étape 2 — Phase 2 (Bestiaire) : drops de ressources dans monster_loot + probabilité des spawns.
-- Migrations appliquées uniquement sur volume vierge (convention du dépôt infra).

ALTER TABLE monster_loot ADD COLUMN resource TEXT;   -- drop de ressource (ex. 'bois', 'fer', 'ore_ether'…)
ALTER TABLE monster_loot DROP CONSTRAINT monster_loot_check;
ALTER TABLE monster_loot ADD CONSTRAINT monster_loot_check
  CHECK (item_id IS NOT NULL OR divine_id IS NOT NULL OR resource IS NOT NULL);

ALTER TABLE spawn_rules ADD COLUMN probability NUMERIC NOT NULL DEFAULT 100 CHECK (probability BETWEEN 0 AND 100);
ALTER TABLE spawn_rules ADD COLUMN last_spawned_at TIMESTAMPTZ;   -- pour la fréquence (interval_h)

ALTER TABLE character_items ADD COLUMN qty INT NOT NULL DEFAULT 1;   -- empilement des butins/achats

ALTER TABLE spawn_rules ADD COLUMN active BOOL NOT NULL DEFAULT TRUE;   -- règle activable/désactivable
