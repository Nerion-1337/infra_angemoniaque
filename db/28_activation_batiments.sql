SET search_path TO game_schema;
-- Lot E (2026-11-25) : conditions d'activation de la capacité d'un bâtiment (portail : franchir ; autre : ses sorts « à activer »).
-- buildings.activation = { groups: [ { items, divine, spellId, resources, gold, minRank, ranks, consume } ] } :
-- il suffit d'UN groupe rempli ; dans un groupe, toutes les conditions renseignées sont exigées. {} = comportement historique.
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS activation JSONB NOT NULL DEFAULT '{}';
