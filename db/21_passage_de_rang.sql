SET search_path TO game_schema;
-- Étape 2 — Lot 3 : conditions de passage de rang réglables par rang (onglet Races & Rangs).
--  - specializations.requirements (JSONB) : ce qu'il faut pour PASSER à ce rang depuis le rang précédent :
--    { "items": [{ "itemId": n, "qty": n }], "resources": { "<id>": qté }, "energyCost": n,
--      "mode": "permanent" | "temporary", "durationH": n, "consume": bool }
--    {} = pas de passage par conditions (le passage historique par objets divins reste possible).
--  - characters.temp_rank (JSONB) : rang temporaire en cours { prevSpec, until, stats } ; à l'échéance le tick
--    rétablit le rang et les caractéristiques d'avant.
-- Idempotent.

ALTER TABLE specializations ADD COLUMN IF NOT EXISTS requirements JSONB NOT NULL DEFAULT '{}';
ALTER TABLE characters ADD COLUMN IF NOT EXISTS temp_rank JSONB;
