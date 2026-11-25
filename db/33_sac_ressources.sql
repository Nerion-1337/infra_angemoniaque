SET search_path TO game_schema;
-- Ressources rangées dans le sac et le coffre : elles occupent des EMPLACEMENTS, par piles. `resource_rules.stack_max` = quantité
-- d'une ressource par emplacement (sac et coffre ; défaut 20, réglable en admin « Ressources »). Une ligne peut désormais exister
-- sans condition de récolte (harvest.groups vide).
-- Sac de taille propre au personnage (`characters.bag_size`, 20 par défaut) : un parchemin d'agrandissement (objet « scroll »,
-- data = { kind: 'bag', add, max }) l'augmente de `add` jusqu'à `max`. Ressources du coffre : `characters.chest_resources`.
-- Idempotent.
ALTER TABLE resource_rules ADD COLUMN IF NOT EXISTS stack_max INT NOT NULL DEFAULT 20;
DO $$ BEGIN ALTER TABLE resource_rules ADD CONSTRAINT chk_stack_max CHECK (stack_max BETWEEN 1 AND 100000); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS bag_size INT NOT NULL DEFAULT 20;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS chest_resources JSONB NOT NULL DEFAULT '{}';
