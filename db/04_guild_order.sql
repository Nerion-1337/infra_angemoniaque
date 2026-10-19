SET search_path TO game_schema;
-- Forum de guilde : ordre d'affichage des catégories et des sujets (réorganisation par les créateurs autorisés).
-- Colonne par défaut 0 : l'ordre historique (id) est préservé via ORDER BY sort_order, id.
ALTER TABLE guild_folders ADD COLUMN sort_order INT NOT NULL DEFAULT 0;
ALTER TABLE guild_topics ADD COLUMN sort_order INT NOT NULL DEFAULT 0;
