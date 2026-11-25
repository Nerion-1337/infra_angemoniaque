SET search_path TO game_schema;
-- Lot C (2026-11-25) : un objet peut offrir (ou retirer) n'importe quelle caractéristique du joueur ; armure magique partout.
--  - Force, agilité, armure, armure magique : colonnes historiques de l'objet, comptées à la volée (back : gearStats).
--  - PV max, régénération, énergie max, énergie divine max, vue, portée : items.bonuses { stat: valeur }, reportés sur la fiche
--    du personnage à l'équipement et retirés au déséquipement / à la disparition de l'objet porté (trigger trg_item_bonus).
--    character_items.applied mémorise ce qui a été ajouté : le retrait est exact même si l'objet a été modifié entre-temps.
ALTER TABLE characters ADD COLUMN IF NOT EXISTS magic_armor INT NOT NULL DEFAULT 0;
ALTER TABLE items      ADD COLUMN IF NOT EXISTS bonuses JSONB NOT NULL DEFAULT '{}';
ALTER TABLE character_items ADD COLUMN IF NOT EXISTS applied JSONB;
ALTER TABLE buildings  ADD COLUMN IF NOT EXISTS bonus_magic_armor INT NOT NULL DEFAULT 0;   -- occupant d'une case de bâtiment

-- sign = 1 (équipe) ou -1 (retire). Réserves ramenées sous leur max ; PV max jamais sous 1, le reste jamais sous 0.
CREATE OR REPLACE FUNCTION apply_item_bonus(cid INT, b JSONB, sign INT) RETURNS void AS $$
BEGIN
  IF b IS NULL OR b = '{}'::jsonb THEN RETURN; END IF;
  UPDATE characters SET
    hp_max            = GREATEST(1, COALESCE(hp_max, 0) + sign * COALESCE((b->>'hp_max')::int, 0)),
    recovery          = GREATEST(0, COALESCE(recovery, 0) + sign * COALESCE((b->>'recovery')::int, 0)),
    energy_max        = GREATEST(0, COALESCE(energy_max, 0) + sign * COALESCE((b->>'energy_max')::int, 0)),
    divine_energy_max = GREATEST(0, COALESCE(divine_energy_max, 0) + sign * COALESCE((b->>'divine_energy_max')::int, 0)),
    see               = GREATEST(0, COALESCE(see, 0) + sign * COALESCE((b->>'see')::int, 0)),
    range             = GREATEST(0, COALESCE(range, 0) + sign * COALESCE((b->>'range')::int, 0))
  WHERE id = cid;
  UPDATE characters SET hp_current = LEAST(hp_current, hp_max), energy_current = LEAST(energy_current, energy_max),
    divine_energy_current = LEAST(divine_energy_current, divine_energy_max) WHERE id = cid;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION item_bonus_trg() RETURNS trigger AS $$
DECLARE b JSONB;
BEGIN
  -- retrait : déséquipé, ou ligne portée supprimée (vente, mort, admin…)
  IF TG_OP IN ('UPDATE', 'DELETE') AND OLD.equipped_slot IS NOT NULL AND (TG_OP = 'DELETE' OR NEW.equipped_slot IS NULL) THEN
    PERFORM apply_item_bonus(OLD.character_id, OLD.applied, -1);
    IF TG_OP = 'UPDATE' THEN NEW.applied := NULL; END IF;
  END IF;
  -- ajout : nouvellement équipé
  IF TG_OP IN ('INSERT', 'UPDATE') AND NEW.equipped_slot IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.equipped_slot IS NULL) THEN
    SELECT NULLIF(bonuses, '{}'::jsonb) INTO b FROM items WHERE id = NEW.item_id;
    NEW.applied := b;
    PERFORM apply_item_bonus(NEW.character_id, b, 1);
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_item_bonus ON character_items;
CREATE TRIGGER trg_item_bonus BEFORE INSERT OR UPDATE OF equipped_slot OR DELETE ON character_items
  FOR EACH ROW EXECUTE FUNCTION item_bonus_trg();
