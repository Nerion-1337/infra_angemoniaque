SET search_path TO game_schema;
-- Annonces et forum public (accessibles depuis l'écran d'accueil), pages légales, acceptation des CGU, signalements.
--  - forum_categories : `kind` announce | forum ; lecture `read_access` public | members | staff ; écriture `post_access`
--    members | staff ; restrictions `races` (vide = toutes) et `min_rank` (rang minimal d'un des personnages du compte) ;
--    `locked` (plus de nouveaux messages) ; `hidden` (visible du staff seulement). Le staff (rôles mod / admin) passe outre.
--  - forum_topics / forum_posts : épinglé, verrouillé, masqué ; message modifié (`edited_at`, `edited_by`).
--  - forum_reports : signalement d'un message par un membre (traitement par le staff).
--  - accounts.tos_version : version des CGU acceptée (écrire exige la version en vigueur) ; accounts.forum_muted_until.
--  - legal_pages : CGU, confidentialité, mentions légales, règlement du forum, cookies (texte brut, version).
-- Idempotent.
CREATE TABLE IF NOT EXISTS forum_categories (
  id SERIAL PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', kind TEXT NOT NULL DEFAULT 'forum',
  position INT NOT NULL DEFAULT 0, read_access TEXT NOT NULL DEFAULT 'public', post_access TEXT NOT NULL DEFAULT 'members',
  races JSONB NOT NULL DEFAULT '[]', min_rank INT NOT NULL DEFAULT 1, locked BOOL NOT NULL DEFAULT FALSE, hidden BOOL NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_forum_cat CHECK (kind IN ('announce','forum') AND read_access IN ('public','members','staff') AND post_access IN ('members','staff')
    AND min_rank BETWEEN 1 AND 10 AND jsonb_typeof(races)='array'));
CREATE TABLE IF NOT EXISTS forum_topics (
  id SERIAL PRIMARY KEY, category_id INT NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE, account_id INT REFERENCES accounts(id) ON DELETE SET NULL,
  title TEXT NOT NULL, pinned BOOL NOT NULL DEFAULT FALSE, locked BOOL NOT NULL DEFAULT FALSE, hidden BOOL NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), last_post_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX IF NOT EXISTS idx_forum_topics_cat ON forum_topics(category_id, pinned DESC, last_post_at DESC);
CREATE TABLE IF NOT EXISTS forum_posts (
  id SERIAL PRIMARY KEY, topic_id INT NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE, account_id INT REFERENCES accounts(id) ON DELETE SET NULL,
  body TEXT NOT NULL, hidden BOOL NOT NULL DEFAULT FALSE, edited_at TIMESTAMPTZ, edited_by INT REFERENCES accounts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX IF NOT EXISTS idx_forum_posts_topic ON forum_posts(topic_id, id);
CREATE TABLE IF NOT EXISTS forum_reports (
  id SERIAL PRIMARY KEY, post_id INT NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE, account_id INT REFERENCES accounts(id) ON DELETE SET NULL,
  reason TEXT NOT NULL, resolved_at TIMESTAMPTZ, resolved_by INT REFERENCES accounts(id) ON DELETE SET NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (post_id, account_id));
CREATE TABLE IF NOT EXISTS legal_pages (
  key TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, position INT NOT NULL DEFAULT 0, version INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS tos_version INT;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS tos_accepted_at TIMESTAMPTZ;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS forum_muted_until TIMESTAMPTZ;

INSERT INTO forum_categories (name, description, kind, position, read_access, post_access, races, min_rank)
SELECT * FROM (VALUES
  ('Annonces', 'Nouvelles officielles de l''équipe : mises à jour, événements, maintenances.', 'announce', 0, 'public', 'staff', '[]'::jsonb, 1),
  ('Place publique', 'Discussions générales entre joueurs des trois mondes.', 'forum', 1, 'public', 'members', '[]'::jsonb, 1),
  ('Aide et questions', 'Débuter, comprendre une règle, demander conseil.', 'forum', 2, 'public', 'members', '[]'::jsonb, 1),
  ('Suggestions et bugs', 'Proposer une idée ou signaler un problème du jeu.', 'forum', 3, 'public', 'members', '[]'::jsonb, 1),
  ('Taverne des Hommes', 'Réservé aux joueurs ayant un personnage humain.', 'forum', 4, 'members', 'members', '["human"]'::jsonb, 1),
  ('Cercle infernal', 'Réservé aux joueurs ayant un personnage démon.', 'forum', 5, 'members', 'members', '["demon"]'::jsonb, 1),
  ('Conclave céleste', 'Réservé aux joueurs ayant un personnage ange.', 'forum', 6, 'members', 'members', '["angel"]'::jsonb, 1),
  ('Salle des Immortels', 'Réservé aux joueurs ayant atteint le rang 3.', 'forum', 7, 'members', 'members', '[]'::jsonb, 3)
) v(name, description, kind, position, read_access, post_access, races, min_rank)
WHERE NOT EXISTS (SELECT 1 FROM forum_categories);

INSERT INTO legal_pages (key, title, position, body) VALUES
('cgu', 'Conditions générales d''utilisation', 0, $cgu$Dernière mise à jour : voir la date de version en bas de page.

1. Objet
Les présentes conditions générales d'utilisation (CGU) encadrent l'accès au jeu en ligne « Angemoniaque » (le « Service »), à son forum et à ses annonces. Créer un compte, se connecter ou publier un message vaut acceptation des CGU en vigueur.

2. Accès au Service et compte
Le Service est gratuit, accessible à toute personne d'au moins 15 ans (en dessous, avec l'accord d'un titulaire de l'autorité parentale). Le joueur fournit une adresse email valide ; la connexion peut aussi se faire avec un compte Google. Il garde ses identifiants confidentiels et répond de l'usage de son compte. Un compte est personnel : prêt, vente ou partage interdits.

3. Règles de conduite
Sont interdits : les propos injurieux, diffamatoires, haineux, discriminatoires, harcelants, violents ou à caractère sexuel ; l'usurpation d'identité ; la publication de données personnelles d'autrui ; la publicité et le spam ; la triche (logiciels tiers, exploitation volontaire de bugs, comptes multiples au-delà de la limite) ; toute atteinte au bon fonctionnement du Service. Le règlement du forum précise ces règles.

4. Contenus publiés
Le joueur reste responsable des messages qu'il publie. Il accorde à l'éditeur, pour la durée de leur mise en ligne, le droit de les afficher sur le Service. L'équipe de modération peut modifier, masquer ou supprimer tout contenu contraire aux CGU ou à la loi, et restreindre l'accès d'un compte (mise en sourdine, suspension, suppression), sans préjudice d'éventuelles poursuites.

5. Signalement
Tout contenu manifestement illicite peut être signalé avec le bouton « Signaler » présent sous chaque message, ou à l'adresse de contact des mentions légales. Les signalements sont examinés par l'équipe dans les meilleurs délais.

6. Propriété intellectuelle
Le jeu, ses textes, graphismes, codes et marques appartiennent à l'éditeur ou à ses partenaires. Toute reproduction non autorisée est interdite.

7. Disponibilité et responsabilité
Le Service est fourni « en l'état » ; l'éditeur s'efforce d'en assurer la disponibilité sans pouvoir la garantir (maintenances, incidents). Les objets, monnaies et personnages du jeu n'ont aucune valeur monétaire et ne sont pas la propriété du joueur.

8. Données personnelles
Le traitement des données est décrit dans la politique de confidentialité.

9. Modification des CGU
L'éditeur peut modifier les CGU ; la nouvelle version est publiée sur le Service et doit être acceptée pour continuer à publier sur le forum.

10. Droit applicable
Les CGU sont soumises au droit français. À défaut d'accord amiable, les tribunaux compétents sont ceux désignés par la loi. Le joueur consommateur peut recourir gratuitement à un médiateur de la consommation.$cgu$),
('privacy', 'Politique de confidentialité', 1, $pv$Responsable du traitement : l'éditeur indiqué dans les mentions légales.

Données collectées
- Compte : adresse email, mot de passe chiffré (ou identifiant Google si vous vous connectez avec Google : identifiant, email vérifié).
- Jeu : personnages, progression, actions, messages en jeu et sur le forum, journaux techniques (date de connexion, erreurs).
- Aucune donnée bancaire n'est collectée.

Finalités et bases légales
- Fournir le jeu et le forum (exécution du contrat : les CGU).
- Assurer la sécurité, la modération et la lutte contre la triche (intérêt légitime).
- Répondre aux obligations légales (conservation de certaines données de connexion, réponses aux autorités).

Durées de conservation
- Données du compte : tant que le compte est actif, puis suppression ou anonymisation dans un délai de 3 ans d'inactivité.
- Messages du forum : tant qu'ils sont en ligne ; les messages supprimés peuvent être conservés au plus 1 an pour la gestion des litiges.
- Données de connexion : 1 an.

Destinataires
L'équipe du jeu et ses sous-traitants techniques (hébergeur). Google reçoit uniquement la demande d'authentification si vous choisissez « Se connecter avec Google ». Aucune vente de données.

Vos droits
Accès, rectification, effacement, limitation, opposition et portabilité, ainsi que le droit de définir des directives après votre décès. Écrivez à l'adresse de contact des mentions légales. Vous pouvez saisir la CNIL (www.cnil.fr).

Cookies et stockage local
Voir la page « Cookies ».$pv$),
('legal', 'Mentions légales', 2, $ml$Éditeur du site : [nom ou raison sociale à compléter], [forme juridique, capital, RCS / SIRET à compléter], [adresse à compléter].
Directeur de la publication : [nom à compléter].
Contact : [adresse email de contact à compléter].

Hébergeur : [nom, adresse et téléphone de l'hébergeur à compléter].

Signalement de contenus illicites : bouton « Signaler » sous chaque message du forum, ou par email à l'adresse de contact ci-dessus en précisant le contenu, sa localisation et les motifs du signalement.$ml$),
('rules', 'Règlement du forum', 3, $rg$1. Restez courtois : pas d'insulte, de provocation ni d'attaque personnelle.
2. Pas de contenu haineux, discriminatoire, violent, sexuel ou illégal.
3. Postez dans la bonne catégorie et donnez un titre clair à vos sujets.
4. Pas de spam, de publicité, de flood, ni de messages hors sujet répétés.
5. Ne publiez aucune donnée personnelle (la vôtre ou celle d'autrui).
6. Le commerce d'objets ou de comptes contre de l'argent réel est interdit.
7. Les décisions de modération se discutent en privé avec l'équipe, pas sur le forum.
8. Sanctions possibles : message masqué ou supprimé, sujet verrouillé, mise en sourdine temporaire, suspension du compte.$rg$),
('cookies', 'Cookies', 4, $ck$Le jeu n'utilise ni cookie publicitaire ni outil de mesure d'audience.
- Stockage local du navigateur (localStorage) : votre jeton de session, pour rester connecté. Il est strictement nécessaire au service et ne demande pas de consentement.
- Cookie temporaire « g_state » (10 minutes) lors d'une connexion avec Google : protection contre la falsification de la demande de connexion. Strictement nécessaire.
Vous pouvez effacer ces données à tout moment depuis votre navigateur (vous serez alors déconnecté).$ck$)
ON CONFLICT (key) DO NOTHING;
