SET search_path TO game_schema;
-- Lot du 2026-11-28 (3). Idempotent.
-- 1. Structures comme les monstres : TYPES (`is_type`, sans position : réglages globaux) et structures POSÉES qui s'y rattachent
--    (`type_id`). Une structure posée garde ses propres valeurs pour les colonnes listées dans `overrides` et pour les clés de
--    `own_data` ; tout le reste suit son type (recopié par l'admin à chaque modification du type).
--    Reprise : un type « Capitale » (d'après l'Hôtel de ville) et un type « Porte » (d'après la Brèche de Soufre) ; ce qui diffère
--    dans chaque capitale / porte devient individuel.
-- 2. Apparence d'une structure (`model` : clé du rendu 3D, NULL = selon son type de construction).
-- 3. Or déposé dans le coffre de la capitale (`characters.chest_gold`).
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS model TEXT CHECK (model IS NULL OR model ~ '^[a-z0-9_]{1,40}$');
ALTER TABLE characters ADD COLUMN IF NOT EXISTS chest_gold BIGINT NOT NULL DEFAULT 0 CHECK (chest_gold >= 0);
DO $$
DECLARE cols TEXT[] := ARRAY['kind','invulnerable','visible','structure','xp_hit','armor','size','occupiable','bonus_armor','bonus_magic_armor','bonus_see',
  'bonus_range','occupant_attack','prerequisites','activation','activations','peace_radius','nobuild_radius','respawn','respawn_delay_h','respawn_limits','realm','leads_to','model'];
  t RECORD; c TEXT; diff BOOLEAN;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='buildings' AND column_name='type_id') THEN RETURN; END IF;
  ALTER TABLE buildings ADD COLUMN is_type BOOLEAN NOT NULL DEFAULT false;
  ALTER TABLE buildings ADD COLUMN type_id INT REFERENCES buildings(id) ON DELETE SET NULL;
  ALTER TABLE buildings ADD COLUMN overrides TEXT[] NOT NULL DEFAULT '{}';
  ALTER TABLE buildings ADD COLUMN own_data JSONB NOT NULL DEFAULT '{}';
  INSERT INTO buildings(name, kind, invulnerable, visible, structure, xp_hit, armor, size, occupiable, bonus_armor, bonus_magic_armor, bonus_see, bonus_range,
      occupant_attack, prerequisites, activation, activations, peace_radius, nobuild_radius, respawn, respawn_delay_h, respawn_limits, realm, leads_to, data, is_type)
    SELECT 'Capitale', kind, invulnerable, visible, structure, xp_hit, armor, size, occupiable, bonus_armor, bonus_magic_armor, bonus_see, bonus_range,
      occupant_attack, prerequisites, activation, activations, peace_radius, nobuild_radius, respawn, respawn_delay_h, respawn_limits, realm, leads_to, data - 'race', true
    FROM buildings WHERE kind='capital' AND name='Hôtel de ville';
  INSERT INTO buildings(name, kind, invulnerable, visible, structure, xp_hit, armor, size, occupiable, bonus_armor, bonus_magic_armor, bonus_see, bonus_range,
      occupant_attack, prerequisites, activation, activations, peace_radius, nobuild_radius, respawn, respawn_delay_h, respawn_limits, realm, leads_to, data, is_type)
    SELECT 'Porte', kind, invulnerable, visible, structure, xp_hit, armor, size, occupiable, bonus_armor, bonus_magic_armor, bonus_see, bonus_range,
      occupant_attack, prerequisites, activation, activations, peace_radius, nobuild_radius, respawn, respawn_delay_h, respawn_limits, realm, leads_to, data - 'to', true
    FROM buildings WHERE kind='door' AND name='Brèche de Soufre';
  FOR t IN SELECT id, kind FROM buildings WHERE is_type LOOP
    UPDATE buildings SET type_id=t.id WHERE NOT is_type AND kind=t.kind AND owner_id IS NULL;
    FOREACH c IN ARRAY cols LOOP
      EXECUTE format('UPDATE buildings b SET overrides = array_append(b.overrides, %L) FROM buildings ty WHERE b.type_id=ty.id AND ty.id=$1 AND b.%I IS DISTINCT FROM ty.%I', c, c, c) USING t.id;
    END LOOP;
    UPDATE buildings b SET own_data = COALESCE((SELECT jsonb_object_agg(k, v) FROM jsonb_each(b.data) e(k, v) WHERE ty.data -> k IS DISTINCT FROM v), '{}')
      FROM buildings ty WHERE b.type_id=ty.id AND ty.id=t.id;
  END LOOP;
END $$;
