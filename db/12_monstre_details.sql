SET search_path TO game_schema;
-- Étape 2 — Phase 3 (détails de monstre) : compétences/sorts, équipement par slot,
-- auras (sorts appliqués en continu, périmètre, alliés/ennemis), réincarnation différée.
-- Volume vierge : joué par l'entrypoint ; volume existant : rattrapé par scripts/migrate.sh.

-- Compétences/sorts du monstre : pioche dans le catalogue global spells (base de sorts du jeu).
CREATE TABLE monster_spells (
  id SERIAL PRIMARY KEY,
  monster_id INT NOT NULL REFERENCES monsters(id) ON DELETE CASCADE,
  spell_id INT NOT NULL REFERENCES spells(id) ON DELETE CASCADE,
  UNIQUE (monster_id, spell_id)
);

-- Équipement du monstre : objet du catalogue items + slot où il est porté
-- (les 7 slots du dossier : mains, tête, torse, pieds, collier, bracelet, bague).
CREATE TABLE monster_equips (
  id SERIAL PRIMARY KEY,
  monster_id INT NOT NULL REFERENCES monsters(id) ON DELETE CASCADE,
  item_id INT NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  slot TEXT NOT NULL CHECK (slot IN ('mains','tete','torse','pieds','collier','bracelet','bague')),
  UNIQUE (monster_id, item_id)
);

-- Auras : bonus/malus appliqués EN CONTINU par un sort (sans consommation de l'énergie du sort)
-- dans un périmètre autour du monstre, sur les alliés ou les ennemis.
CREATE TABLE monster_auras (
  id SERIAL PRIMARY KEY,
  monster_id INT NOT NULL REFERENCES monsters(id) ON DELETE CASCADE,
  spell_id INT NOT NULL REFERENCES spells(id) ON DELETE CASCADE,
  target TEXT NOT NULL CHECK (target IN ('ally','enemy')),
  radius INT NOT NULL DEFAULT 3,
  UNIQUE (monster_id, spell_id, target)
);

-- Durée d'effet des sorts (buffs/auras) : NULL = indéfini (utilisé par les auras).
ALTER TABLE spells ADD COLUMN duration_h INT;

-- Réincarnation : délai (heures) entre la mort d'un monstre ancré et sa régénération.
-- 0 (défaut) = régénération instantanée (comportement historique, inchangé).
ALTER TABLE monsters ADD COLUMN reincarnate_delay_h INT NOT NULL DEFAULT 0 CHECK (reincarnate_delay_h >= 0);
CREATE TABLE monster_respawns (
  monster_id INT PRIMARY KEY REFERENCES monsters(id) ON DELETE CASCADE,
  due_at TIMESTAMPTZ NOT NULL
);
