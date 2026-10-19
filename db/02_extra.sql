SET search_path TO game_schema;
CREATE TABLE accounts (id SERIAL PRIMARY KEY, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, is_admin BOOL DEFAULT FALSE);
CREATE TABLE guilds (id SERIAL PRIMARY KEY, name TEXT UNIQUE NOT NULL, leader_id INT REFERENCES characters(id));
ALTER TABLE characters ADD COLUMN portrait TEXT, ADD COLUMN guild_id INT REFERENCES guilds(id), ADD COLUMN chest_size INT DEFAULT 10,
  ADD COLUMN resources JSONB DEFAULT '{}', ADD COLUMN last_vision_read TIMESTAMPTZ DEFAULT now(), ADD COLUMN last_guild_read TIMESTAMPTZ DEFAULT now();
ALTER TABLE characters ADD CONSTRAINT fk_acc FOREIGN KEY (account_id) REFERENCES accounts(id);
ALTER TABLE faiths ADD COLUMN request_choice TEXT;
ALTER TABLE items ADD COLUMN price INT, ADD COLUMN shop BOOL DEFAULT FALSE, ADD COLUMN shop_stock INT DEFAULT 0, ADD COLUMN armor INT DEFAULT 0, ADD COLUMN strength_bonus INT DEFAULT 0,
  ADD COLUMN agility_bonus INT DEFAULT 0, ADD COLUMN req_strength INT DEFAULT 0, ADD COLUMN weapon_damage INT DEFAULT 0, ADD COLUMN magic_armor INT DEFAULT 0;
ALTER TABLE mounts ADD COLUMN strength INT DEFAULT 18, ADD COLUMN agility INT DEFAULT 12, ADD COLUMN recovery INT DEFAULT 10, ADD COLUMN aquatic BOOL DEFAULT FALSE,
  ADD COLUMN special_attack_name TEXT, ADD COLUMN special_attack_damage INT DEFAULT 0, ADD COLUMN special_attack_energy INT DEFAULT 15;
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
-- Objets du dépôt : équipement de départ (non vendus) + boutique de faction (avec réserve)
INSERT INTO items(name,slot,rarity,quantity_max,price,shop,shop_stock,armor,strength_bonus,agility_bonus,req_strength,weapon_damage,data) VALUES
 ('Épée Sanctifiée','weapon','Épique',50,NULL,false,0,0,0,0,2,3,'{}'),('Écu de la Garde','shield','Commun',9999,NULL,false,0,6,0,0,1,0,'{}'),
 ('Casque de Fer Forgé','head','Commun',9999,NULL,false,0,4,0,0,1,0,'{}'),('Plastron du Lion','chest','Rare',500,NULL,false,0,10,0,0,2,0,'{}'),
 ('Bottes de Célérité','foot','Rare',500,NULL,false,0,3,0,2,1,0,'{}'),('Anneau de Rubis','ring','Rare',500,NULL,false,0,0,2,0,0,0,'{}'),
 ('Sceptre du Lien','special','Rare',100,NULL,false,0,0,0,0,0,0,'{"bonusSummons":1}'),
 ('Pioche de Récolte','weapon','Commun',9999,80,true,12,0,0,0,1,2,'{}'),('Lance de la Milice','weapon','Commun',9999,160,true,8,0,0,0,2,3,'{}'),
 ('Tunique Matelassée','chest','Commun',9999,120,true,10,5,0,0,1,0,'{}'),
 ('Parchemin de mur','scroll','Commun',9999,30,true,50,0,0,0,0,0,'{"kind":"wall"}'),('Parchemin de tour','scroll','Commun',9999,80,true,30,0,0,0,0,0,'{"kind":"tower"}'),
 ('Parchemin de navire','scroll','Rare',300,400,true,5,0,0,0,0,0,'{"kind":"ship"}'),
 ('Parchemin d’usine','scroll','Rare',200,300,false,0,0,0,0,0,0,'{"kind":"factory"}'),('Parchemin de totem','scroll','Rare',200,300,false,0,0,0,0,0,0,'{"kind":"totem"}');
INSERT INTO items(name,slot,rarity,quantity_max,price,shop,shop_stock,armor,magic_armor,req_strength,data) VALUES ('Robe de Lumière','chest','Rare',300,140,true,6,2,8,1,'{}');
INSERT INTO mounts(name,hp_max,armor,energy_max,bonus_see,bonus_range,flying,aquatic,strength,agility,recovery,special_attack_name,special_attack_damage,special_attack_energy) VALUES
 ('Dragon de Rubis Ancien',450,20,120,2,2,true,false,18,12,15,'Cracher du feu',65,15),('Destrier Céleste Cuirassé',220,12,90,1,1,false,false,14,12,10,NULL,0,15),
 ('Hippocampe des Abysses',180,8,100,1,0,false,true,14,14,12,NULL,0,15),('Navire',150,5,100,1,0,false,true,10,6,8,NULL,0,15);
