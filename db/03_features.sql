SET search_path TO game_schema;
-- ===== Invocations contrôlables =====
CREATE TABLE summons (id SERIAL PRIMARY KEY, owner_id INT NOT NULL REFERENCES characters(id) ON DELETE CASCADE, name TEXT NOT NULL, hp_current INT, hp_max INT, energy_current INT, energy_max INT,
  recovery INT DEFAULT 5, see INT DEFAULT 4, strength INT DEFAULT 12, agility INT DEFAULT 8, armor INT DEFAULT 10, damage INT DEFAULT 12);
ALTER TABLE positions ADD COLUMN summon_id INT REFERENCES summons(id) ON DELETE CASCADE;
ALTER TABLE positions DROP CONSTRAINT chk_exclusive_entity;
ALTER TABLE positions ADD CONSTRAINT chk_exclusive_entity CHECK (num_nonnulls(character_id,monsters_id,building_id,mount_id,item_id,summon_id)=1);
ALTER TABLE characters ADD COLUMN controlled_summon_id INT REFERENCES summons(id) ON DELETE SET NULL, ADD COLUMN summon_cap INT DEFAULT 1, ADD COLUMN guild_rank_id INT;
-- ===== Sorts =====
ALTER TABLE spells ADD COLUMN kind TEXT, ADD COLUMN energy_cost INT DEFAULT 10, ADD COLUMN damage INT DEFAULT 0, ADD COLUMN description TEXT, ADD COLUMN price INT DEFAULT 100;
INSERT INTO spells(name,kind,energy_cost,damage,description,price) VALUES
 ('Invocation : Golem d’Éther','summon',15,0,'Invoque un Golem contrôlable sur une case adjacente libre.',120),
 ('Lien d’Invocateur','summon_cap',20,0,'Augmente de 1 votre limite d’invocations simultanées.',200),
 ('Fureur Céleste','buff',10,0,'Force +4 et Agilité +4 pendant 1 h.',60),
 ('Trait de Lumière','attack',12,45,'Inflige 45 dégâts magiques sur la case ciblée.',90);

-- ===== Guildes : présentation, rangs & droits, postulants, invitations, forum par rang =====
ALTER TABLE guilds ADD COLUMN tag TEXT, ADD COLUMN logo TEXT, ADD COLUMN mantra TEXT DEFAULT '', ADD COLUMN description TEXT DEFAULT '';
CREATE TABLE guild_ranks (id SERIAL PRIMARY KEY, guild_id INT REFERENCES guilds(id) ON DELETE CASCADE, name TEXT NOT NULL, is_leader BOOL DEFAULT FALSE, permissions JSONB DEFAULT '{}', UNIQUE(guild_id,name));
ALTER TABLE characters ADD CONSTRAINT fk_rank FOREIGN KEY (guild_rank_id) REFERENCES guild_ranks(id) ON DELETE SET NULL;
CREATE TABLE guild_applications (id SERIAL PRIMARY KEY, guild_id INT REFERENCES guilds(id) ON DELETE CASCADE, character_id INT REFERENCES characters(id) ON DELETE CASCADE, UNIQUE(guild_id,character_id));
CREATE TABLE guild_invitations (id SERIAL PRIMARY KEY, guild_id INT REFERENCES guilds(id) ON DELETE CASCADE, character_id INT REFERENCES characters(id) ON DELETE CASCADE, from_id INT, UNIQUE(guild_id,character_id));
ALTER TABLE guild_folders ADD COLUMN visible_ranks TEXT[] DEFAULT '{}'; ALTER TABLE guild_topics ADD COLUMN visible_ranks TEXT[] DEFAULT '{}';
ALTER TABLE messages ADD COLUMN subject TEXT;

-- ===== Pactes sur demande : l'autre partie doit accepter ; plusieurs demandes envoyées et reçues =====
ALTER TABLE pacts ADD COLUMN requested_by INT REFERENCES characters(id), ADD COLUMN status TEXT DEFAULT 'active';
ALTER TABLE pacts ALTER COLUMN active SET DEFAULT FALSE; ALTER TABLE pacts ADD CONSTRAINT uq_pact_pair UNIQUE (ethereal_id, human_id);
