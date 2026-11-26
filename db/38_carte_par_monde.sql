SET search_path TO game_schema;
-- Carte des ressources PAR MONDE : `characters.map_worlds` (mondes dont le personnage a la carte des ressources) remplace le
-- booléen `map_upgrade`. L'achat à l'Hôtel de ville n'ouvre que le monde de la capitale où il est fait ; un parchemin de carte
-- des ressources par monde (objet « scroll », data = { kind: 'resource_map', map_id }) ouvre son monde quand on l'utilise ;
-- l'admin les place ensuite (boutique, butin, kit de départ, don à un joueur). Idempotent.
ALTER TABLE characters ADD COLUMN IF NOT EXISTS map_worlds INT[] NOT NULL DEFAULT '{}';
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='characters' AND column_name='map_upgrade') THEN
    UPDATE characters c SET map_worlds = ARRAY[COALESCE((SELECT p.map_id FROM buildings b JOIN positions p ON p.building_id=b.id
      WHERE b.kind='capital' AND b.data->>'race'=c.race LIMIT 1), 1)] WHERE c.map_upgrade AND c.map_worlds='{}';
    ALTER TABLE characters DROP COLUMN map_upgrade;
  END IF;
END $$;
INSERT INTO items (name, slot, rarity, data, price)
SELECT 'Parchemin de carte des ressources — ' || CASE m.id WHEN 1 THEN 'Monde des Hommes' WHEN 2 THEN 'Monde des Anges et des Démons'
    WHEN 3 THEN 'Monde des Morts' ELSE m.name_file END, 'scroll', 'rare', jsonb_build_object('kind', 'resource_map', 'map_id', m.id), 500
FROM maps m WHERE NOT EXISTS (SELECT 1 FROM items i WHERE i.data->>'kind'='resource_map' AND (i.data->>'map_id')::int=m.id);
