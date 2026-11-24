SET search_path TO game_schema;
-- Étape 2 — Lot 2 : moteur de sorts paramétrable et liens sort ↔ objet / monture / bâtiment.
--  - spells.effects (JSONB) : cible (self | single | area), portée, rayon, camp visé, dégâts instantanés, soin,
--    dégâts par heure pendant N heures, modifications de caractéristiques (± valeur, durée ou permanent).
--    {} = sort historique (comportement codé par `kind` : summon, summon_cap, buff, attack).
--  - spell_dots : dégâts sur la durée en cours (appliqués au tick horaire, jamais mortels).
--  - entity_spells : sort lié à un objet (lançable / passif quand il est équipé), une monture (quand elle est active)
--    ou un bâtiment (lot 4). Les monstres gardent leur table monster_spells.
-- Idempotent.

ALTER TABLE spells ADD COLUMN IF NOT EXISTS effects JSONB NOT NULL DEFAULT '{}';

CREATE TABLE IF NOT EXISTS spell_dots (
  id           SERIAL PRIMARY KEY,
  target_kind  TEXT NOT NULL CHECK (target_kind IN ('character', 'monster', 'summon')),
  target_id    INT  NOT NULL,
  spell_id     INT  REFERENCES spells(id) ON DELETE CASCADE,
  caster_id    INT  REFERENCES characters(id) ON DELETE SET NULL,
  damage_per_h INT  NOT NULL CHECK (damage_per_h > 0),
  until        TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS spell_dots_target ON spell_dots(target_kind, target_id);

CREATE TABLE IF NOT EXISTS entity_spells (
  id       SERIAL PRIMARY KEY,
  kind     TEXT NOT NULL CHECK (kind IN ('item', 'mount', 'building')),
  ref_id   INT  NOT NULL,
  spell_id INT  NOT NULL REFERENCES spells(id) ON DELETE CASCADE,
  mode     TEXT NOT NULL DEFAULT 'active' CHECK (mode IN ('active', 'passive')),
  UNIQUE (kind, ref_id, spell_id, mode)
);
