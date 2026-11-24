SET search_path TO game_schema;
-- Étape 2 — Lot 5 : gisements de ressources (onglet admin « Ressources »).
-- Un gisement place une ressource du catalogue sur une zone rectangulaire d'un monde (x_min..x_max × y_min..y_max ;
-- une seule case si min = max) avec un STOCK partagé par toute la zone : chaque récolte sur une case de la zone donne
-- `yield_per_harvest` (borné par le stock restant) et le retire du stock ; le tick horaire régénère `regen_per_h`
-- jusqu'à `stock_max`. Stock vide → « Gisement épuisé ». Hors gisement, la récolte du terrain reste illimitée (+1).
-- Si plusieurs gisements couvrent une case, le plus petit (puis le plus récent) l'emporte.
-- Idempotent.

CREATE TABLE IF NOT EXISTS resource_deposits (
  id                SERIAL PRIMARY KEY,
  map_id            INT  NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  x_min             INT  NOT NULL CHECK (x_min >= 0),
  y_min             INT  NOT NULL CHECK (y_min >= 0),
  x_max             INT  NOT NULL,
  y_max             INT  NOT NULL,
  resource          TEXT NOT NULL,
  stock             INT  NOT NULL CHECK (stock >= 0),
  stock_max         INT  NOT NULL CHECK (stock_max >= 1),
  regen_per_h       INT  NOT NULL DEFAULT 0 CHECK (regen_per_h >= 0),
  yield_per_harvest INT  NOT NULL DEFAULT 1 CHECK (yield_per_harvest >= 1),
  active            BOOL NOT NULL DEFAULT TRUE,
  CHECK (x_max >= x_min AND y_max >= y_min)
);
CREATE INDEX IF NOT EXISTS resource_deposits_map ON resource_deposits(map_id);
