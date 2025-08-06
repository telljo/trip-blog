CREATE TABLE IF NOT EXISTS "action_text_rich_texts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "body" text, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_action_text_rich_texts_uniqueness" ON "action_text_rich_texts" ("record_type", "record_id", "name") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar NOT NULL, "password_digest" varchar NOT NULL, "verified" boolean DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "username" varchar);
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email") /*application='TripBlog'*/;
CREATE UNIQUE INDEX "index_users_on_username" ON "users" ("username") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='TripBlog'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "post_comment_likes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "post_comment_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_b7c083c14a"
FOREIGN KEY ("post_comment_id")
  REFERENCES "post_comments" ("id")
, CONSTRAINT "fk_rails_0c49ec6b6a"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_post_comment_likes_on_post_comment_id" ON "post_comment_likes" ("post_comment_id") /*application='TripBlog'*/;
CREATE INDEX "index_post_comment_likes_on_user_id" ON "post_comment_likes" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "post_comment_replies" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "content" text, "post_comment_id" integer NOT NULL, "user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_80cfb4e917"
FOREIGN KEY ("post_comment_id")
  REFERENCES "post_comments" ("id")
, CONSTRAINT "fk_rails_25e8d0bd48"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_post_comment_replies_on_post_comment_id" ON "post_comment_replies" ("post_comment_id") /*application='TripBlog'*/;
CREATE INDEX "index_post_comment_replies_on_user_id" ON "post_comment_replies" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "post_comments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "content" text, "post_id" integer NOT NULL, "user_id" integer NOT NULL, "like_count" integer DEFAULT 0, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_bfdc8d8659"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
, CONSTRAINT "fk_rails_56efacbd2f"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_post_comments_on_post_id" ON "post_comments" ("post_id") /*application='TripBlog'*/;
CREATE INDEX "index_post_comments_on_user_id" ON "post_comments" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "user_agent" varchar, "ip_address" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_758836b4f0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_sessions_on_user_id" ON "sessions" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "trip_companions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "trip_id" integer NOT NULL, "accepted" boolean DEFAULT 0, "declined" boolean DEFAULT 0, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_496845cddc"
FOREIGN KEY ("trip_id")
  REFERENCES "trips" ("id")
, CONSTRAINT "fk_rails_dfff3986bc"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_trip_companions_on_trip_id" ON "trip_companions" ("trip_id") /*application='TripBlog'*/;
CREATE INDEX "index_trip_companions_on_user_id" ON "trip_companions" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "trip_followers" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "trip_id" integer NOT NULL, "user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_696066d81f"
FOREIGN KEY ("trip_id")
  REFERENCES "trips" ("id")
, CONSTRAINT "fk_rails_bdf11a8dfe"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_trip_followers_on_trip_id" ON "trip_followers" ("trip_id") /*application='TripBlog'*/;
CREATE INDEX "index_trip_followers_on_user_id" ON "trip_followers" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "trips" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_6a33c9e4ea"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_trips_on_user_id" ON "trips" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "user_post_likes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "post_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_60872e1cc9"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
, CONSTRAINT "fk_rails_8218827802"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_user_post_likes_on_post_id" ON "user_post_likes" ("post_id") /*application='TripBlog'*/;
CREATE INDEX "index_user_post_likes_on_user_id" ON "user_post_likes" ("user_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "post_attachment_captions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "attachment_id" integer NOT NULL, "post_id" integer NOT NULL, "text" text NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_13cd6be8c6"
FOREIGN KEY ("attachment_id")
  REFERENCES "active_storage_attachments" ("id")
, CONSTRAINT "fk_rails_1103e40dff"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
);
CREATE INDEX "index_post_attachment_captions_on_attachment_id" ON "post_attachment_captions" ("attachment_id") /*application='TripBlog'*/;
CREATE INDEX "index_post_attachment_captions_on_post_id" ON "post_attachment_captions" ("post_id") /*application='TripBlog'*/;
CREATE TABLE IF NOT EXISTS "posts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar, "body" text, "latitude" float, "longitude" float, "street" varchar, "city" varchar, "state" varchar, "country" varchar, "trip_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "user_id" integer, "draft" boolean DEFAULT 0 NOT NULL /*application='TripBlog'*/, "notified_at" datetime(6) DEFAULT NULL /*application='TripBlog'*/, "travel_type" integer DEFAULT NULL /*application='TripBlog'*/, "hidden" boolean DEFAULT 0 NOT NULL /*application='TripBlog'*/, CONSTRAINT "fk_rails_35843b2bd6"
FOREIGN KEY ("trip_id")
  REFERENCES "trips" ("id")
);
CREATE INDEX "index_posts_on_trip_id" ON "posts" ("trip_id") /*application='TripBlog'*/;
CREATE INDEX "index_posts_on_draft" ON "posts" ("draft") /*application='TripBlog'*/;
CREATE INDEX "index_posts_on_notified_at" ON "posts" ("notified_at") /*application='TripBlog'*/;
CREATE INDEX "index_posts_on_country" ON "posts" ("country") /*application='TripBlog'*/;
CREATE INDEX "index_posts_on_hidden" ON "posts" ("hidden") /*application='TripBlog'*/;
CREATE VIRTUAL TABLE post_fts USING fts5(
  title,
  body,
  country,
  city,
  content='',
  prefix='2 3 4'
)
/* post_fts(title,body,country,city) */;
CREATE TABLE IF NOT EXISTS 'post_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'post_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'post_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'post_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
INSERT INTO "schema_migrations" (version) VALUES
('20250711162259'),
('20250711045052'),
('20250621061742'),
('20250619063008'),
('20250319060944'),
('20250301063414'),
('20250220160224'),
('20250220082413'),
('20250125071431'),
('20250123041626'),
('20250118200256'),
('20241218010522'),
('20241124015105'),
('20241121021416'),
('20241116102908'),
('20241114221054'),
('20241114221053'),
('20241114220018'),
('20241114215711'),
('20241114215710');

