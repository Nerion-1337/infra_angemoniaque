SET search_path TO game_schema;
-- Coût en ÉNERGIE DIVINE, à côté du coût en énergie, de tout ce qui en consomme et se règle dans l'admin : sorts, recettes de
-- fabrication (parchemins), déplacement par type de case. 0 par défaut (aucune action n'en exige) ; payé par le personnage
-- (jamais par sa monture ou son invocation). Le passage de rang (`specializations.requirements`, JSON) porte `divineEnergyCost`
-- par voie, sans colonne. Idempotent.
ALTER TABLE spells     ADD COLUMN IF NOT EXISTS divine_energy_cost INT NOT NULL DEFAULT 0 CHECK (divine_energy_cost >= 0);
ALTER TABLE recipes    ADD COLUMN IF NOT EXISTS divine_energy_cost INT NOT NULL DEFAULT 0 CHECK (divine_energy_cost >= 0);
ALTER TABLE tile_types ADD COLUMN IF NOT EXISTS divine_energy_cost INT NOT NULL DEFAULT 0 CHECK (divine_energy_cost >= 0);
