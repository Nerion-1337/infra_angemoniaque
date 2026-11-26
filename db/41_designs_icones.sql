SET search_path TO game_schema;
-- Design 3D et icône d'un type de monstre (admin « Monstres ») : `monsters.model` = clé du catalogue des designs du front
-- (lib/creatureCatalog.js : 30 aériens, 40 terrestres, 15 aquatiques), `monsters.icon` = clé d'icône (lib/creatureIcons.js).
-- NULL = automatique (design reconnu par le nom, sinon tiré dans le milieu ; icône du design). Recopiés sur les monstres posés
-- ou apparus ; une monture et une invocation prennent ceux de leur type. Idempotent.
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS model TEXT;
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS icon TEXT;
DO $$ BEGIN ALTER TABLE monsters ADD CONSTRAINT chk_monster_look CHECK ((model IS NULL OR model ~ '^[a-z0-9_]{1,40}$') AND (icon IS NULL OR icon ~ '^[a-z0-9_]{1,40}$'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
