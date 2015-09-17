-- Adminer 4.2.2 SQLite 3 dump

DROP TABLE IF EXISTS "album";
CREATE TABLE "album" (
  "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  "name" text NOT NULL,
  "artist_id" integer NOT NULL,
  "style" text NOT NULL,
  "year" integer NOT NULL,
  FOREIGN KEY ("artist_id") REFERENCES "artist" ("id") ON DELETE CASCADE
);

INSERT INTO "album" ("id", "name", "artist_id", "style", "year") VALUES (1,	'依然范特西',	1,	'流行樂',	2006);
INSERT INTO "album" ("id", "name", "artist_id", "style", "year") VALUES (2,	'十八般武藝',	2,	'流行樂',	2010);

DROP TABLE IF EXISTS "artist";
CREATE TABLE "artist" (
  "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  "name" text NOT NULL
);

INSERT INTO "artist" ("id", "name") VALUES (1,	'周杰倫');
INSERT INTO "artist" ("id", "name") VALUES (2,	'王力宏');

DROP TABLE IF EXISTS "playlist";
CREATE TABLE "playlist" (
  "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  "name" text NOT NULL
);

INSERT INTO "playlist" ("id", "name") VALUES (1,	'周杰倫歷年精選');
INSERT INTO "playlist" ("id", "name") VALUES (2,	'王力宏歷年精選');

DROP TABLE IF EXISTS "playlist_song";
CREATE TABLE "playlist_song" (
  "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  "playlist_id" integer NOT NULL,
  "song_id" integer NOT NULL,
  FOREIGN KEY ("playlist_id") REFERENCES "playlist" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY ("song_id") REFERENCES "song" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX "playlist_song_playlist_id" ON "playlist_song" ("playlist_id");

CREATE INDEX "playlist_song_song_id" ON "playlist_song" ("song_id");

INSERT INTO "playlist_song" ("id", "playlist_id", "song_id") VALUES (1,	1,	1);
INSERT INTO "playlist_song" ("id", "playlist_id", "song_id") VALUES (2,	1,	2);
INSERT INTO "playlist_song" ("id", "playlist_id", "song_id") VALUES (3,	1,	3);
INSERT INTO "playlist_song" ("id", "playlist_id", "song_id") VALUES (4,	2,	4);
INSERT INTO "playlist_song" ("id", "playlist_id", "song_id") VALUES (5,	2,	5);
INSERT INTO "playlist_song" ("id", "playlist_id", "song_id") VALUES (6,	2,	6);

DROP TABLE IF EXISTS "song";
CREATE TABLE "song" (
  "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  "name" text NOT NULL,
  "artist_id" integer NOT NULL,
  "album_id" integer NOT NULL,
  FOREIGN KEY ("album_id") REFERENCES "album" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY ("artist_id") REFERENCES "artist" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

INSERT INTO "song" ("id", "name", "artist_id", "album_id") VALUES (1,	'聽媽媽的話',	1,	1);
INSERT INTO "song" ("id", "name", "artist_id", "album_id") VALUES (2,	'千里之外',	1,	1);
INSERT INTO "song" ("id", "name", "artist_id", "album_id") VALUES (3,	'菊花台',	1,	1);
INSERT INTO "song" ("id", "name", "artist_id", "album_id") VALUES (4,	'十八般武藝',	2,	2);
INSERT INTO "song" ("id", "name", "artist_id", "album_id") VALUES (5,	'你不知道的事',	2,	2);
INSERT INTO "song" ("id", "name", "artist_id", "album_id") VALUES (6,	'美',	2,	2);

DROP TABLE IF EXISTS "sqlite_sequence";
CREATE TABLE sqlite_sequence(name,seq);

INSERT INTO "sqlite_sequence" ("name", "seq") VALUES ('playlist_song',	'6');
INSERT INTO "sqlite_sequence" ("name", "seq") VALUES ('playlist',	'2');
INSERT INTO "sqlite_sequence" ("name", "seq") VALUES ('artist',	'2');
INSERT INTO "sqlite_sequence" ("name", "seq") VALUES ('song',	'6');
INSERT INTO "sqlite_sequence" ("name", "seq") VALUES ('album',	'2');

-- 
