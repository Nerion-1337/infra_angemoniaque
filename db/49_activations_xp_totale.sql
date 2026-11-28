SET search_path TO game_schema;
-- Lot du 2026-11-28 (suite). Idempotent.
-- 1. XP totale accumulée (`characters.xp_total`) : toute hausse de `xp` s'y ajoute (trigger) ; dépenser de l'XP (améliorations)
--    ne la baisse pas ; seule la mort en retire (code). Reprise : XP actuelle (l'XP déjà dépensée avant ce lot n'est pas connue).
-- 2. Structure visible ou non sur la carte des joueurs (`buildings.visible`).
-- 3. Éléments d'activation d'une structure (`buildings.activations`) : alternatives { kind: item | divine | spell | gold | xp,
--    ref, qty, hours (NULL = définitif), consume } ; activée jusqu'à `open_until` ('infinity' = définitivement). Les portes des
--    mondes reprennent leur ancienne règle : 1 objet divin de leur famille, consommé, `open_h_per_item` heures.
ALTER TABLE characters ADD COLUMN IF NOT EXISTS xp_total BIGINT;
UPDATE characters SET xp_total = GREATEST(xp, 0) WHERE xp_total IS NULL;
CREATE OR REPLACE FUNCTION xp_total_track() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN NEW.xp_total := COALESCE(NEW.xp_total, GREATEST(NEW.xp, 0));
  ELSIF NEW.xp > OLD.xp THEN NEW.xp_total := COALESCE(NEW.xp_total, 0) + (NEW.xp - OLD.xp);
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_xp_total ON characters;
CREATE TRIGGER trg_xp_total BEFORE INSERT OR UPDATE OF xp ON characters FOR EACH ROW EXECUTE FUNCTION xp_total_track();
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS visible BOOLEAN NOT NULL DEFAULT true;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='game_schema' AND table_name='buildings' AND column_name='activations') THEN
    ALTER TABLE buildings ADD COLUMN activations JSONB NOT NULL DEFAULT '[]';
    UPDATE buildings SET activations = jsonb_build_array(jsonb_build_object('kind', 'divine',
        'ref', CASE realm WHEN 'human' THEN 'artefact' WHEN 'demon' THEN 'arcane' ELSE 'relique' END, 'qty', 1, 'hours', open_h_per_item, 'consume', true))
      WHERE kind='door' AND realm IN ('human', 'demon', 'angel');
  END IF;
END $$;
