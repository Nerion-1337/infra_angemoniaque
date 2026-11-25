SET search_path TO game_schema;
-- Conditions de récolte par ressource du catalogue (onglet admin « Ressources ») : objets (équipés ou dans le sac), sort connu,
-- ressources, or, rang… au format des conditions d'activation des bâtiments (migration 28) : { "groups": [ … ] }, groupes
-- alternatifs, `consume` pour retirer ce qui est exigé. Valent sur le terrain naturel comme dans les secteurs. Sans ligne : libre.
-- La ressource n'a pas de clé étrangère (catalogue en code) : vérifiée par l'API. Idempotent.
CREATE TABLE IF NOT EXISTS resource_rules (
  resource TEXT PRIMARY KEY,
  harvest  JSONB NOT NULL DEFAULT '{"groups": []}'
);
