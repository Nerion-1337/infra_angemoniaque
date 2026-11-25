SET search_path TO game_schema;
-- Lot A (2026-11-25) : passage de rang à deux voies et réapparition des monstres réglable par type.
--  1) specializations.requirements : ancien format { mode, durationH, items… } → { permanent: {…}|null, temporary: {…, durationH}|null }
--     (les deux voies peuvent coexister ; le joueur choisit). Idempotent : ne touche que l'ancien format.
UPDATE specializations SET requirements = CASE WHEN requirements->>'mode' = 'temporary'
    THEN jsonb_build_object('permanent', NULL, 'temporary', requirements - 'mode')
    ELSE jsonb_build_object('permanent', requirements - 'mode' - 'durationH', 'temporary', NULL) END
  WHERE requirements IS NOT NULL AND requirements <> '{}'::jsonb AND NOT (requirements ? 'permanent' OR requirements ? 'temporary');
--  2) monsters.respawn : recréé ou non après sa mort (délai : reincarnate_delay_h, migration 12) ;
--     monsters.respawn_limits : [{ kind: item|spell|resource, ref, max }] — pas de réapparition tant qu'il y a au moins
--     `max` exemplaires de l'élément chez les joueurs ; rechecké à chaque tick, il réapparaît dès que ce n'est plus le cas.
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS respawn BOOL NOT NULL DEFAULT TRUE;
ALTER TABLE monsters ADD COLUMN IF NOT EXISTS respawn_limits JSONB NOT NULL DEFAULT '[]';
