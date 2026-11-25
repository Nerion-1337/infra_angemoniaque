SET search_path TO game_schema;
-- Lot D (2026-11-25) : un sort peut INVOQUER un élément (monstre, monture, objet, bâtiment), de façon permanente ou temporaire ;
-- un élément (objet, monture, bâtiment) peut porter des sorts liés, avec leur mode d'application.
--  - entity_spells.mode : active (à activer : lançable), passive (en continu), on_hit (objet : à chaque coup porté),
--    on_struck (objet : à chaque attaque reçue).
--  - spell_summons : invocations temporaires à retirer à l'échéance (tick). ref_id = summons.id (monstre), mounts.id (monture),
--    items.id (objet, `qty` exemplaires) ou buildings.id (copie posée).
ALTER TABLE entity_spells DROP CONSTRAINT IF EXISTS entity_spells_mode_check;
ALTER TABLE entity_spells DROP CONSTRAINT IF EXISTS chk_entity_spells_mode;
ALTER TABLE entity_spells ADD CONSTRAINT chk_entity_spells_mode CHECK (mode IN ('active', 'passive', 'on_hit', 'on_struck'));

CREATE TABLE IF NOT EXISTS spell_summons (
  id        SERIAL PRIMARY KEY,
  caster_id INT  NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  kind      TEXT NOT NULL CHECK (kind IN ('monster', 'mount', 'item', 'building')),
  ref_id    INT  NOT NULL,
  qty       INT  NOT NULL DEFAULT 1 CHECK (qty >= 1),
  until     TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS spell_summons_until ON spell_summons(until);
