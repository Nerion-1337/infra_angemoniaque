SET search_path TO game_schema;
-- Étape 2 — Phase 3b (capacités) : les sorts du monstre deviennent des CAPACITÉS :
--  - mode 'active'   : sort que le monstre peut LANCER (à la demande),
--  - mode 'passive'  : sort qu'il possède par défaut, appliqué EN CONTINU sans consommation
--    d'énergie (cible alliés/ennemis + périmètre) — les auras de la migration 12 y sont
--    fusionnées (la table monster_auras disparaît).
--  + parties du corps équipables par type de monstre (grille style personnage :
--    mains / tête / torse / pieds / collier / bracelet / bague).
-- Volume vierge : joué par l'entrypoint ; volume existant : rattrapé par scripts/migrate.sh.

ALTER TABLE monster_spells ADD COLUMN mode TEXT NOT NULL DEFAULT 'active' CHECK (mode IN ('active','passive'));
ALTER TABLE monster_spells ADD COLUMN target TEXT CHECK (target IN ('ally','enemy')), ADD COLUMN radius INT;
ALTER TABLE monster_spells DROP CONSTRAINT monster_spells_monster_id_spell_id_key;
ALTER TABLE monster_spells ADD CONSTRAINT uq_monster_spells UNIQUE (monster_id, spell_id, mode);

-- Transition : les auras (migration 12) deviennent des capacités passives.
INSERT INTO monster_spells(monster_id, spell_id, mode, target, radius)
  SELECT monster_id, spell_id, 'passive', target, radius FROM monster_auras
  ON CONFLICT (monster_id, spell_id, mode) DO NOTHING;
DROP TABLE monster_auras;

-- Parties du corps équipables (par type de monstre) : grille 7 slots, même style que
-- l'équipement personnage. Liste vide = aucune restriction (tous les slots autorisés).
CREATE TABLE monster_slots (
  monster_id INT NOT NULL REFERENCES monsters(id) ON DELETE CASCADE,
  slot TEXT NOT NULL CHECK (slot IN ('mains','tete','torse','pieds','collier','bracelet','bague')),
  PRIMARY KEY (monster_id, slot)
);
