SET search_path TO game_schema;
-- Étape 2 — Lot 1 : boutique par race et parchemins de fabrication.
--  - items.shop_races / spells.shop + spells.shop_races : disponibilité dans la boutique de l'hôtel de ville
--    (shop = vendu ; shop_races = races autorisées, [] = toutes). Un objet/sort hors boutique ne s'obtient qu'en jeu
--    (butin, récolte…) ou par fabrication. Les sorts restent tous en boutique par défaut (comportement historique).
--  - recipes : un parchemin (objet du catalogue) + des ressources permettent de fabriquer un objet, d'apprendre un
--    sort ou de bâtir une copie d'un bâtiment modèle. Par recette : parchemin consommé ou non, fabrication à
--    l'hôtel de ville seulement ou partout, coût en énergie.
-- Idempotent.

ALTER TABLE items  ADD COLUMN IF NOT EXISTS shop_races JSONB NOT NULL DEFAULT '[]';
ALTER TABLE spells ADD COLUMN IF NOT EXISTS shop BOOL NOT NULL DEFAULT TRUE;
ALTER TABLE spells ADD COLUMN IF NOT EXISTS shop_races JSONB NOT NULL DEFAULT '[]';

CREATE TABLE IF NOT EXISTS recipes (
  id             SERIAL PRIMARY KEY,
  scroll_item_id INT  NOT NULL UNIQUE REFERENCES items(id) ON DELETE CASCADE,
  target_kind    TEXT NOT NULL CHECK (target_kind IN ('item', 'spell', 'building')),
  target_id      INT  NOT NULL,
  qty_out        INT  NOT NULL DEFAULT 1 CHECK (qty_out BETWEEN 1 AND 999),
  resources      JSONB NOT NULL DEFAULT '{}',
  consume_scroll BOOL NOT NULL DEFAULT TRUE,
  at_capital     BOOL NOT NULL DEFAULT FALSE,
  energy_cost    INT  NOT NULL DEFAULT 0 CHECK (energy_cost BETWEEN 0 AND 1000)
);
