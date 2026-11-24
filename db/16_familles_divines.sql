SET search_path TO game_schema;
-- Étape 2 — Objets divins : même architecture que les autres objets + familles libres.
--  - divine_families : familles d'objets uniques (relique / arcane / artefact + celles créées en admin),
--    avec le plafond global d'exemplaires (cap ; NULL = illimité) — remplace game_config.divine_caps.
--  - items.divine_family : un objet de rareté « divin » est un objet du catalogue (nom, slot, stats,
--    qui peut s'en équiper…) rattaché à une famille.
--  - divine_items.item_id : chaque EXEMPLAIRE unique (détenteur / gardien) pointe vers son objet modèle ;
--    divine_items.kind reste la famille (la logique de jeu : rangs par race, portes, butin, est inchangée).
-- Idempotent.

CREATE TABLE IF NOT EXISTS divine_families (
  key  TEXT PRIMARY KEY CHECK (key ~ '^[a-z][a-z0-9_]{1,29}$'),
  name TEXT NOT NULL,
  cap  INT CHECK (cap IS NULL OR cap >= 0)
);
INSERT INTO divine_families(key, name, cap)
SELECT k.key, k.name, COALESCE((SELECT (value->>k.key)::int FROM game_config WHERE key='divine_caps'), k.cap)
FROM (VALUES ('relique','Reliques',4), ('arcane','Arcanes',4), ('artefact','Artefacts',5)) AS k(key, name, cap)
ON CONFLICT (key) DO NOTHING;

-- La famille d'un exemplaire n'est plus limitée aux 3 valeurs : clé étrangère vers divine_families.
ALTER TABLE divine_items DROP CONSTRAINT IF EXISTS divine_items_kind_check;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='divine_items_kind_fk') THEN
    ALTER TABLE divine_items ADD CONSTRAINT divine_items_kind_fk FOREIGN KEY (kind) REFERENCES divine_families(key) ON UPDATE CASCADE;
  END IF;
END $$;

ALTER TABLE items ADD COLUMN IF NOT EXISTS divine_family TEXT REFERENCES divine_families(key) ON UPDATE CASCADE;
ALTER TABLE divine_items ADD COLUMN IF NOT EXISTS item_id INT REFERENCES items(id);

-- Reprise de l'existant : un objet modèle par famille historique, auquel on rattache les exemplaires orphelins.
INSERT INTO items(name, rarity, divine_family, quantity_max)
SELECT f.name_one, 'divin', f.key, NULL
FROM (VALUES ('relique','Relique'), ('arcane','Arcane'), ('artefact','Artefact')) AS f(key, name_one)
WHERE NOT EXISTS (SELECT 1 FROM items i WHERE i.divine_family = f.key);
UPDATE divine_items di SET item_id = (SELECT min(i.id) FROM items i WHERE i.divine_family = di.kind)
WHERE di.item_id IS NULL;
