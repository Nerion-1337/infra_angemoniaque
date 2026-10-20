SET search_path TO game_schema;
-- Rang par défaut de guilde : le rang attribué par défaut aux nouveaux arrivants
-- (candidats acceptés, invitations rejoins). NULL = automatique (rang non-Chef le plus bas).
-- Une seule option par guilde : une colonne, pas un jeu de drapeaux.
ALTER TABLE guilds ADD COLUMN default_rank_id INT REFERENCES guild_ranks(id);
