SET search_path TO game_schema;
-- Étape 2 — Types de case éditables par monde (section admin « Cases »).
-- Une ligne par (monde, type de terrain) : nom et description affichés en jeu, coût
-- d'énergie d'un pas sur la case (remplace KIND_COST côté serveur) et, en option, un
-- sort appliqué EN CONTINU (chaque tick horaire) aux personnages qui s'y trouvent :
-- spell_mode 'bonus' = +dégâts du sort en PV, 'malus' = -dégâts (PV min. 1, jamais mortel).
-- La géométrie des cartes (quel type sur quelle case) reste générée dans le code.
-- Idempotent : rejouable sans effet (IF NOT EXISTS / ON CONFLICT DO NOTHING).

CREATE TABLE IF NOT EXISTS tile_types (
  map_id      INT  NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  kind        TEXT NOT NULL CHECK (kind IN ('plain','forest','mountain','arid','snow','ether','volcano','shallow','deep')),
  name        TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  energy_cost INT  NOT NULL CHECK (energy_cost BETWEEN 0 AND 99),
  spell_id    INT  REFERENCES spells(id) ON DELETE SET NULL,
  spell_mode  TEXT CHECK (spell_mode IN ('bonus','malus')),
  PRIMARY KEY (map_id, kind)
);

-- Valeurs actuelles du code (terrain.ts KIND_COST / KIND_LABEL) : aucun changement de jeu à l'application.
-- Monde 1 (Hommes) et 2 (Anges & Démons) : les 9 types ; monde 3 (Morts, procédural) : 5 types.
INSERT INTO tile_types(map_id, kind, name, description, energy_cost)
SELECT m.id, k.kind, k.name, k.descr, k.cost
FROM maps m
JOIN (VALUES
  ('plain',    'Plaine',           'Terrain dégagé, le plus rapide à parcourir.', 1),
  ('forest',   'Forêt',            'Sous-bois dense : on y récolte du bois.', 2),
  ('mountain', 'Massif rocheux',   'Roche et minerais ; la marche y est lente.', 3),
  ('arid',     'Terre aride',      'Sol sec et craquelé.', 2),
  ('snow',     'Pics glacés',      'Neige profonde et vent glacial.', 3),
  ('ether',    'Pics d’éther',     'Sommets imprégnés d’énergie divine.', 3),
  ('volcano',  'Volcan',           'Traverser une case de lave brûle le héros pendant plusieurs heures.', 3),
  ('shallow',  'Eau peu profonde', 'Praticable à pied, mais épuisant.', 4),
  ('deep',     'Eau profonde',     'Infranchissable à pied : navire, monture volante ou aquatique requis.', 99)
) AS k(kind, name, descr, cost) ON m.id IN (1, 2) OR (m.id = 3 AND k.kind IN ('plain','forest','mountain','shallow','deep'))
ON CONFLICT (map_id, kind) DO NOTHING;
