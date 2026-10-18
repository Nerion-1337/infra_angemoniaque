CREATE SCHEMA IF NOT EXISTS game_schema; SET search_path TO game_schema;
CREATE TABLE maps (id SERIAL PRIMARY KEY, name_file TEXT NOT NULL, width INT NOT NULL, height INT NOT NULL);
INSERT INTO maps(name_file,width,height) VALUES ('humains.map',200,200),('anges_demons.map',200,200),('morts.map',100,100);
CREATE TABLE specializations (id SERIAL PRIMARY KEY, race TEXT NOT NULL CHECK (race IN ('human','demon','angel','nephilim')),
  name TEXT NOT NULL, current_rank INT NOT NULL, max_population_percent NUMERIC NOT NULL, gain_xp_hour INT,
  hp_max INT, recovery INT, see INT, strength INT, agility INT, energy_max INT, divine_energy_max INT);
INSERT INTO specializations(race,name,current_rank,max_population_percent,gain_xp_hour,hp_max,recovery,see,strength,agility,energy_max,divine_energy_max) VALUES
('human','Mortel',1,100,2,100,5,5,5,5,50,0),('human','Héros',2,50,12,200,8,8,10,10,65,0),
('human','Immortel',3,25,23,500,10,10,14,14,80,0),('human','Demi-Dieu',4,10,35,1200,12,12,20,20,100,20),
('human','Divin',5,0.1,210,2000,20,20,40,40,200,50),
('demon','Soldat',2,100,3,200,8,8,10,10,65,0),('demon','Duc',3,50,23,500,10,10,14,14,80,0),
('demon','Titan',4,25,35,1200,12,12,20,20,100,20),('demon','Divin',5,0.1,210,2000,20,20,40,40,200,50),
('angel','Soldat',2,100,3,200,8,8,10,10,65,0),('angel','Archange',3,50,23,500,10,10,14,14,80,0),
('angel','Séraphin',4,25,35,1200,12,12,20,20,100,20),('angel','Divin',5,0.1,210,2000,20,20,40,40,200,50),
('nephilim','Soldat',3,10,3,400,12,12,15,15,90,10),('nephilim','Immortel',4,5,3,800,15,15,30,30,150,35);
CREATE TABLE stat_cost_rules (stat TEXT PRIMARY KEY, base_xp_cost INT, numb_up INT, multi_1 NUMERIC DEFAULT 1.0, multi_2 NUMERIC DEFAULT 2.0, multi_3 NUMERIC DEFAULT 3.0);
INSERT INTO stat_cost_rules(stat,base_xp_cost,numb_up) VALUES ('hp_max',2,50),('energy_max',10,20),('divine_energy_max',20,20),('recovery',25,10),('see',25,10),('strength',50,10),('agility',50,10);
CREATE TABLE characters (id SERIAL PRIMARY KEY, account_id INT NOT NULL, pseudo TEXT UNIQUE NOT NULL, race TEXT NOT NULL,
  specialization_id INT REFERENCES specializations(id), hp_current INT, hp_max INT, recovery INT, energy_current INT, energy_max INT,
  divine_energy_current INT DEFAULT 0, divine_energy_max INT DEFAULT 0, strength INT, agility INT, armor INT DEFAULT 0, range INT DEFAULT 1,
  see INT, xp INT DEFAULT 0, gold INT DEFAULT 0, blocked BOOLEAN DEFAULT FALSE, upgrades JSONB DEFAULT '{}');
CREATE FUNCTION chk_char_limit() RETURNS trigger AS $$ BEGIN
  IF (SELECT count(*) FROM characters WHERE account_id=NEW.account_id)>=3 THEN RAISE EXCEPTION '3 personnages max'; END IF;
  IF EXISTS (SELECT 1 FROM characters WHERE account_id=NEW.account_id AND race<>NEW.race) THEN RAISE EXCEPTION 'Même race obligatoire'; END IF;
  RETURN NEW; END $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_char_limit BEFORE INSERT ON characters FOR EACH ROW EXECUTE FUNCTION chk_char_limit();
CREATE TABLE monsters (id SERIAL PRIMARY KEY, name TEXT, hp_max INT, strength INT, armor INT, see INT, guards_item TEXT);
INSERT INTO monsters(name,hp_max,strength,armor,see,guards_item) VALUES ('Léviathan',3000,50,50,15,'relique'),('Balrog',3000,50,50,15,'arcane'),('Minotaure',1500,25,25,10,'artefact');
CREATE TABLE items (id SERIAL PRIMARY KEY, name TEXT, slot TEXT, rarity TEXT, quantity_max INT, data JSONB DEFAULT '{}');
CREATE TABLE spells (id SERIAL PRIMARY KEY, name TEXT, data JSONB DEFAULT '{}');
CREATE TABLE mounts (id SERIAL PRIMARY KEY, name TEXT, hp_max INT, armor INT, energy_max INT, bonus_see INT DEFAULT 0, bonus_range INT DEFAULT 0, flying BOOL DEFAULT FALSE);
CREATE TABLE buildings (id SERIAL PRIMARY KEY, name TEXT, kind TEXT, invulnerable BOOL DEFAULT FALSE, owner_id INT REFERENCES characters(id), data JSONB DEFAULT '{}');
CREATE TABLE character_monster (character_id INT REFERENCES characters(id), monster_id INT REFERENCES monsters(id), hp_current INT, PRIMARY KEY(character_id,monster_id));
CREATE TABLE character_items (character_id INT REFERENCES characters(id), item_id INT REFERENCES items(id), equipped_slot TEXT);
CREATE TABLE character_spells (character_id INT REFERENCES characters(id), spell_id INT REFERENCES spells(id), effect_active BOOL DEFAULT FALSE, duration_turns_h INT DEFAULT 0);
CREATE TABLE character_mounts (character_id INT REFERENCES characters(id), mount_id INT REFERENCES mounts(id), energy_current INT, hp_current INT, active BOOL DEFAULT FALSE);
CREATE TABLE positions (id SERIAL PRIMARY KEY, map_id INT NOT NULL REFERENCES maps(id), coord_x INT NOT NULL, coord_y INT NOT NULL,
  character_id INT REFERENCES characters(id), monsters_id INT REFERENCES monsters(id), building_id INT REFERENCES buildings(id),
  mount_id INT REFERENCES mounts(id), item_id INT REFERENCES items(id),
  CONSTRAINT chk_exclusive_entity CHECK (num_nonnulls(character_id,monsters_id,building_id,mount_id,item_id)=1));
CREATE UNIQUE INDEX uq_pos_char ON positions(character_id) WHERE character_id IS NOT NULL;
CREATE INDEX idx_pos_xy ON positions(map_id,coord_x,coord_y);
CREATE TABLE pacts (id SERIAL PRIMARY KEY, ethereal_id INT REFERENCES characters(id), human_id INT REFERENCES characters(id), active BOOL DEFAULT TRUE);
CREATE UNIQUE INDEX uq_pact_human ON pacts(human_id) WHERE active;
CREATE TABLE faiths (id SERIAL PRIMARY KEY, god_id INT REFERENCES characters(id), follower_id INT REFERENCES characters(id), status TEXT DEFAULT 'pending', last_request_at TIMESTAMPTZ);
CREATE TABLE history_action (id BIGSERIAL PRIMARY KEY, character_id INT REFERENCES characters(id), action TEXT, created_at TIMESTAMPTZ DEFAULT now());
CREATE TABLE messages (id BIGSERIAL PRIMARY KEY, channel TEXT CHECK (channel IN ('vision','guild','mail')), sender_id INT, map_id INT, guild_id INT, body TEXT, created_at TIMESTAMPTZ DEFAULT now());
CREATE TABLE conversation_participants (message_id BIGINT REFERENCES messages(id), character_id INT REFERENCES characters(id), read BOOL DEFAULT FALSE);
