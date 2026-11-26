SET search_path TO game_schema;
-- Connexion avec Google (OAuth 2.0 / OpenID Connect) : un compte peut être lié à un identifiant Google (`google_sub`, unique) ;
-- un compte créé par Google n'a pas de mot de passe (`password_hash` NULL : la connexion par mot de passe lui est refusée).
-- Idempotent.
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS google_sub TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS uq_accounts_google_sub ON accounts(google_sub) WHERE google_sub IS NOT NULL;
ALTER TABLE accounts ALTER COLUMN password_hash DROP NOT NULL;
