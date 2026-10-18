SET search_path TO game_schema;
CREATE TABLE accounts (id SERIAL PRIMARY KEY, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, is_admin BOOL DEFAULT FALSE);
CREATE TABLE guilds (id SERIAL PRIMARY KEY, name TEXT UNIQUE NOT NULL, leader_id INT REFERENCES characters(id));
ALTER TABLE characters ADD COLUMN portrait TEXT, ADD COLUMN guild_id INT REFERENCES guilds(id), ADD COLUMN chest_size INT DEFAULT 10,
  ADD COLUMN resources JSONB DEFAULT '{}', ADD COLUMN last_vision_read TIMESTAMPTZ DEFAULT now(), ADD COLUMN last_guild_read TIMESTAMPTZ DEFAULT now();
ALTER TABLE characters ADD CONSTRAINT fk_acc FOREIGN KEY (account_id) REFERENCES accounts(id);
ALTER TABLE monsters ADD COLUMN hp_current INT; UPDATE monsters SET hp_current=hp_max;
ALTER TABLE faiths ADD COLUMN request_choice TEXT;
ALTER TABLE items ADD COLUMN price INT, ADD COLUMN shop BOOL DEFAULT FALSE;
ALTER TABLE character_items ADD COLUMN in_chest BOOL DEFAULT FALSE;
CREATE TABLE guild_folders (id SERIAL PRIMARY KEY, guild_id INT REFERENCES guilds(id), name TEXT);
CREATE TABLE guild_topics (id SERIAL PRIMARY KEY, folder_id INT REFERENCES guild_folders(id), title TEXT, author_id INT);
CREATE TABLE guild_posts (id SERIAL PRIMARY KEY, topic_id INT REFERENCES guild_topics(id), author_id INT, body TEXT, created_at TIMESTAMPTZ DEFAULT now());
CREATE TABLE divine_items (id SERIAL PRIMARY KEY, kind TEXT CHECK (kind IN ('relique','arcane','artefact')),
  holder_character_id INT REFERENCES characters(id), guardian_monster_id INT REFERENCES monsters(id));
INSERT INTO divine_items(kind,guardian_monster_id) SELECT 'relique',(SELECT id FROM monsters WHERE name='Léviathan') FROM generate_series(1,4);
INSERT INTO divine_items(kind,guardian_monster_id) SELECT 'arcane',(SELECT id FROM monsters WHERE name='Balrog') FROM generate_series(1,4);
INSERT INTO divine_items(kind,guardian_monster_id) SELECT 'artefact',(SELECT id FROM monsters WHERE name='Minotaure') FROM generate_series(1,5);
CREATE TABLE temp_buffs (id SERIAL PRIMARY KEY, character_id INT REFERENCES characters(id), stat TEXT, delta INT, source TEXT, expires_at TIMESTAMPTZ);
CREATE TABLE market_listings (id SERIAL PRIMARY KEY, seller_id INT REFERENCES characters(id), race TEXT, kind TEXT, ref_id INT, price INT, sold BOOL DEFAULT FALSE);
ALTER TABLE faiths ADD CONSTRAINT uq_faith UNIQUE (god_id, follower_id);
CREATE UNIQUE INDEX uq_cell ON positions(map_id,coord_x,coord_y) WHERE item_id IS NULL;  -- collisions garanties par la base
-- Bâtiments invulnérables : capitales + portes inter-mondes
INSERT INTO buildings(name,kind,invulnerable,data) VALUES
 ('Hôtel de ville','capital',true,'{"race":"human"}'),('Bastion Infernal','capital',true,'{"race":"demon"}'),('Sanctuaire de la Providence','capital',true,'{"race":"angel"}'),
 ('Le Seuil des Deux Voiles','door',true,'{"requires":"artefact","to":[2,12,10]}'),
 ('Brèche de Soufre','door',true,'{"requires":"arcane","to":[1,12,10]}'),
 ('L’Arche de Grâce','door',true,'{"requires":"relique","to":[1,22,10]}');
INSERT INTO positions(map_id,coord_x,coord_y,building_id) SELECT v.m,v.x,v.y,b.id FROM (VALUES
 ('Hôtel de ville',1,100,100),('Bastion Infernal',2,100,100),('Sanctuaire de la Providence',2,110,100),
 ('Le Seuil des Deux Voiles',1,10,10),('Brèche de Soufre',2,10,10),('L’Arche de Grâce',2,20,10)) v(n,m,x,y) JOIN buildings b ON b.name=v.n;
INSERT INTO positions(map_id,coord_x,coord_y,monsters_id) SELECT 2,50,50,id FROM monsters WHERE name='Léviathan';
INSERT INTO positions(map_id,coord_x,coord_y,monsters_id) SELECT 2,150,150,id FROM monsters WHERE name='Balrog';
INSERT INTO positions(map_id,coord_x,coord_y,monsters_id) SELECT 1,150,60,id FROM monsters WHERE name='Minotaure';
INSERT INTO items(name,slot,rarity,quantity_max,price,shop,data) VALUES
 ('Pioche','tool','basic',9999,20,true,'{}'),('Épée courte','weapon','basic',9999,50,true,'{"strength":2}'),
 ('Parchemin de mur','scroll','basic',9999,30,true,'{"kind":"wall"}'),('Parchemin de tour','scroll','basic',9999,80,true,'{"kind":"tower"}'),
 ('Parchemin d’usine','scroll','rare',200,300,false,'{"kind":"factory"}'),('Parchemin de totem','scroll','rare',200,300,false,'{"kind":"totem"}');
INSERT INTO mounts(name,hp_max,armor,energy_max,bonus_see,bonus_range,flying) VALUES ('Cheval',60,2,40,0,0,false),('Dragon',300,15,80,3,2,true);
