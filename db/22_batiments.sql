SET search_path TO game_schema;
-- Étape 2 — Lot 4 : bâtiments paramétrables.
--  - armor : armure de la structure (structure = ses points de vie, colonne existante).
--  - occupiable : un personnage peut se tenir sur la case du bâtiment ; il reçoit alors bonus_armor / bonus_see /
--    bonus_range et n'est attaquable que selon occupant_attack { melee, ranged, spell }.
--  - La production / collecte horaire reste dans data.production / data.collection (+ data.storage, plafonds).
--  - Les sorts de la structure (actifs pour le propriétaire à côté, passifs chaque heure) sont dans entity_spells (lot 2).
-- Unicité des cases : une entité (personnage, monstre, invocation, monture…) au plus par case ET un bâtiment au plus par
-- case (deux index séparés) ; un bâtiment NON occupable continue de bloquer sa case (contrôlé par le code).
-- Idempotent.

ALTER TABLE buildings ADD COLUMN IF NOT EXISTS armor INT NOT NULL DEFAULT 0 CHECK (armor >= 0);
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS occupiable BOOL NOT NULL DEFAULT FALSE;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS occupant_attack JSONB NOT NULL DEFAULT '{"melee": true, "ranged": true, "spell": true}';
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS bonus_armor INT NOT NULL DEFAULT 0;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS bonus_see INT NOT NULL DEFAULT 0;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS bonus_range INT NOT NULL DEFAULT 0;

DROP INDEX IF EXISTS uq_cell;
CREATE UNIQUE INDEX uq_cell ON positions(map_id, coord_x, coord_y) WHERE item_id IS NULL AND building_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_cell_building ON positions(map_id, coord_x, coord_y) WHERE building_id IS NOT NULL;
