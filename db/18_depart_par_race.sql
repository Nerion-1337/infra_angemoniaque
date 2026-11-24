SET search_path TO game_schema;
-- Étape 2 — Équipement de départ par race (onglet admin « Races & Rangs »).
-- races.start_kit (JSONB) décrit ce que reçoit un NOUVEAU personnage de la race :
--   { "rank": <palier> | null (= premier palier), "gold": n, "xp": n, "resources": { "<id catalogue>": qté },
--     "items": [ { "itemId": n, "qty": n, "place": "bag" | "chest" } ], "spells": [ id… ],
--     "mounts": [ { "mountId": n, "active": bool } ] }
-- Reprise : les races existantes reçoivent le kit historique codé en dur (150 or, 6 objets au sac, Destrier
-- Céleste Cuirassé) → aucun changement de jeu à l'application. Idempotent (ne touche pas un kit déjà réglé).

ALTER TABLE races ADD COLUMN IF NOT EXISTS start_kit JSONB NOT NULL DEFAULT '{}';

UPDATE races SET start_kit = jsonb_build_object(
  'rank', NULL, 'gold', 150, 'xp', 0, 'resources', '{}'::jsonb,
  'items', COALESCE((SELECT jsonb_agg(jsonb_build_object('itemId', i.id, 'qty', 1, 'place', 'bag') ORDER BY i.id) FROM items i
                     WHERE i.name IN ('Épée Sanctifiée', 'Écu de la Garde', 'Casque de Fer Forgé', 'Plastron du Lion', 'Bottes de Célérité', 'Anneau de Rubis')), '[]'::jsonb),
  'spells', '[]'::jsonb,
  'mounts', COALESCE((SELECT jsonb_agg(jsonb_build_object('mountId', m.id, 'active', false)) FROM mounts m WHERE m.name = 'Destrier Céleste Cuirassé'), '[]'::jsonb))
WHERE start_kit = '{}'::jsonb;
