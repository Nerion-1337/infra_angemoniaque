SET search_path TO game_schema;
-- Rangs de guilde : ordre d'affichage dans l'onglet Gestion (cartes de rangs réorganisables).
-- Colonne par défaut 0 : l'ordre historique (id) est préservé via ORDER BY sort_order, id.
ALTER TABLE guild_ranks ADD COLUMN sort_order INT NOT NULL DEFAULT 0;
