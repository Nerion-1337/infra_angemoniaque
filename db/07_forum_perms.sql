SET search_path TO game_schema;
-- Forum v2 : descriptions, permissions granulaires Voir (visible_ranks) / Écrire (write_ranks)
-- et suivi des messages lus.
ALTER TABLE guild_folders ADD COLUMN description TEXT, ADD COLUMN write_ranks TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE guild_topics ADD COLUMN description TEXT, ADD COLUMN write_ranks TEXT[];
-- Reprise comportementale : qui pouvait lire pouvait écrire (rang par défaut du forum v1 = create_topics).
UPDATE guild_folders SET write_ranks = COALESCE(visible_ranks, '{}');
-- Sémantique nouvelle : guild_topics.visible_ranks = {} veut dire « hérite de la catégorie »
-- (les lignes existantes sont non vides → aucune régression). guild_topics.write_ranks NULL = hérite.
-- Suivi des lectures : dernier post lu par membre et par sujet (acquittement à l'ouverture du sujet).
CREATE TABLE guild_topic_reads (
  character_id INT NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  topic_id INT NOT NULL REFERENCES guild_topics(id) ON DELETE CASCADE,
  read_post_id INT NOT NULL DEFAULT 0,
  PRIMARY KEY (character_id, topic_id)
);
