SET search_path TO game_schema;
-- Étape 2 — Onglets admin Objets & Sorts.
--  - rareté homogène (5 niveaux : commun / rare / epique / legendaire / divin).
--    « divin » = les objets uniques artefacts/arcanes/reliques (table divine_items).
--  - paramètre « qui peut s'en équiper / l'apprendre » : sous-ensemble de
--    {humain, ange, demon, monstre, structure, monture}. Vide = tout le monde.
--
-- items.rarity existe déjà (texte libre) → on ne pose pas de CHECK dessus pour ne pas
-- casser de données existantes ; les valeurs valides sont imposées par l'API admin.
-- spells.rarity est nouveau → CHECK direct. usable_by est un JSONB (tableau de kinds).

ALTER TABLE items ADD COLUMN IF NOT EXISTS usable_by JSONB NOT NULL DEFAULT '[]';
ALTER TABLE spells ADD COLUMN rarity TEXT NOT NULL DEFAULT 'commun'
  CHECK (rarity IN ('commun','rare','epique','legendaire','divin'));
ALTER TABLE spells ADD COLUMN IF NOT EXISTS usable_by JSONB NOT NULL DEFAULT '[]';
