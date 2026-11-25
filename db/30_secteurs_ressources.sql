SET search_path TO game_schema;
-- Secteurs de ressources (refonte de l'onglet admin « Ressources ») : un gisement (resource_deposits) devient un SECTEUR
-- (zone rectangulaire d'un monde, nom, actif) qui contient une ou plusieurs ressources (deposit_resources). Chaque ressource
-- du secteur a sa part de cases (`percent`), peut être limitée à un type de case (`kind`, ex. bois → forêt) et garde son
-- propre stock (partagé par ses cases), sa régénération et son rendement par récolte. Une case reçoit UNE seule ressource :
-- tirage déterministe (hash de la case et du secteur) parmi les ressources admises sur son type de case ; la part restante
-- (100 % − somme) garde la ressource naturelle du terrain. Somme des parts ≤ 100 % par type de case (vérifiée par l'API).
-- Reprise : chaque ancien gisement devient un secteur à une ressource (100 %, toute case). Idempotent.

ALTER TABLE resource_deposits ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT '';
CREATE TABLE IF NOT EXISTS deposit_resources (
  id                SERIAL PRIMARY KEY,
  deposit_id        INT  NOT NULL REFERENCES resource_deposits(id) ON DELETE CASCADE,
  resource          TEXT NOT NULL,
  percent           INT  NOT NULL DEFAULT 100 CHECK (percent BETWEEN 1 AND 100),
  kind              TEXT CHECK (kind IN ('plain','forest','mountain','arid','snow','ether','volcano','shallow','deep')),
  stock             INT  NOT NULL CHECK (stock >= 0),
  stock_max         INT  NOT NULL CHECK (stock_max >= 1),
  regen_per_h       INT  NOT NULL DEFAULT 0 CHECK (regen_per_h >= 0),
  yield_per_harvest INT  NOT NULL DEFAULT 1 CHECK (yield_per_harvest >= 1),
  UNIQUE (deposit_id, resource)
);
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='resource_deposits' AND column_name='resource') THEN
    INSERT INTO deposit_resources(deposit_id, resource, percent, stock, stock_max, regen_per_h, yield_per_harvest)
      SELECT id, resource, 100, stock, stock_max, regen_per_h, yield_per_harvest FROM resource_deposits ON CONFLICT DO NOTHING;
    ALTER TABLE resource_deposits DROP COLUMN resource, DROP COLUMN stock, DROP COLUMN stock_max, DROP COLUMN regen_per_h, DROP COLUMN yield_per_harvest;
  END IF;
END $$;
