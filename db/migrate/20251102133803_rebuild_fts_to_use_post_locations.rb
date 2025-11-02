class RebuildFtsToUsePostLocations < ActiveRecord::Migration[8.0]
  def up
    # Drop the old virtual table and triggers
    execute "DROP TRIGGER IF EXISTS post_fts_insert;"
    execute "DROP TRIGGER IF EXISTS post_fts_update;"
    execute "DROP TRIGGER IF EXISTS post_fts_delete;"
    execute "DROP TABLE IF EXISTS post_fts;"

    # Recreate the virtual FTS table
    execute <<~SQL
      CREATE VIRTUAL TABLE post_fts USING fts5(
        title,
        body,
        country,
        city,
        content='',
        prefix='2 3 4'
      );
    SQL

    # --- NEW TRIGGERS ---

    # INSERT trigger: when a PostLocation is created, index its parent post
    execute <<~SQL
      CREATE TRIGGER post_fts_insert AFTER INSERT ON post_locations
      BEGIN
        INSERT INTO post_fts (rowid, title, body, country, city)
        SELECT
          posts.id,
          posts.title,
          (SELECT body FROM action_text_rich_texts
           WHERE record_type='Post' AND record_id=posts.id LIMIT 1),
          COALESCE(NEW.country, ''),
          COALESCE(NEW.city, '')
        FROM posts
        WHERE posts.id = NEW.post_id;
      END;
    SQL

    # UPDATE trigger
    execute <<~SQL
      CREATE TRIGGER post_fts_update AFTER UPDATE ON post_locations
      BEGIN
        -- remove the old entry
        INSERT INTO post_fts(post_fts, rowid, title, body, country, city)
        SELECT 'delete', posts.id, posts.title,
               (SELECT body FROM action_text_rich_texts
                WHERE record_type='Post' AND record_id=posts.id LIMIT 1),
               COALESCE(OLD.country, ''), COALESCE(OLD.city, '')
        FROM posts
        WHERE posts.id = OLD.post_id;

        -- insert the new entry
        INSERT INTO post_fts (rowid, title, body, country, city)
        SELECT posts.id,
               posts.title,
               (SELECT body FROM action_text_rich_texts
                WHERE record_type='Post' AND record_id=posts.id LIMIT 1),
               COALESCE(NEW.country, ''),
               COALESCE(NEW.city, '')
        FROM posts
        WHERE posts.id = NEW.post_id;
      END;
    SQL

    # DELETE trigger
    execute <<~SQL
      CREATE TRIGGER post_fts_delete AFTER DELETE ON post_locations
      BEGIN
        INSERT INTO post_fts (post_fts, rowid, title, body, country, city)
        SELECT 'delete', posts.id, posts.title,
               (SELECT body FROM action_text_rich_texts
                WHERE record_type='Post' AND record_id=posts.id LIMIT 1),
               COALESCE(OLD.country, ''), COALESCE(OLD.city, '')
        FROM posts
        WHERE posts.id = OLD.post_id;
      END;
    SQL

    # --- DATA BACKFILL ---
    say_with_time "Rebuilding FTS index from posts and post_locations" do
      Post.includes(:rich_text_body, :post_locations).find_each do |post|
        sanitized_body = ActionView::Base.full_sanitizer.sanitize(post.body&.to_s || "")

        post.post_locations.each do |loc|
          execute <<~SQL
            INSERT INTO post_fts (rowid, title, body, country, city)
            VALUES (
              #{post.id},
              #{ActiveRecord::Base.connection.quote(post.title.presence || "")},
              #{ActiveRecord::Base.connection.quote(sanitized_body)},
              #{ActiveRecord::Base.connection.quote(loc.country.presence || "")},
              #{ActiveRecord::Base.connection.quote(loc.city.presence || "")}
            );
          SQL
        end
      end
    end
  end

  def down
    execute "DROP TABLE IF EXISTS post_fts;"
    execute "DROP TRIGGER IF EXISTS post_fts_insert;"
    execute "DROP TRIGGER IF EXISTS post_fts_update;"
    execute "DROP TRIGGER IF EXISTS post_fts_delete;"
  end
end
