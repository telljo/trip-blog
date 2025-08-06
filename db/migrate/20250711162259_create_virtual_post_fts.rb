class CreateVirtualPostFts < ActiveRecord::Migration[8.0]
  def up
    # Creating virtual table post_fts
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

    # Creating trigger post_fts_insert
    execute <<~SQL
      CREATE TRIGGER post_fts_insert AFTER INSERT ON posts
      BEGIN
        INSERT INTO post_fts (rowid, title, body, country, city)
        VALUES (NEW.id, NEW.title, NEW.body, NEW.country, NEW.city);
      END;
    SQL

    # Creating trigger post_fts_update
    execute <<~SQL
      CREATE TRIGGER post_fts_update AFTER UPDATE ON posts
      BEGIN
        -- Delete the old entry from the FTS table
        INSERT INTO post_fts(post_fts, rowid, title, body, country, city)
        VALUES('delete', old.rowid, old.title, old.body, old.country, old.city);

        -- Insert the new entry into the FTS table
        INSERT INTO post_fts (rowid, title, body, country, city)
        VALUES (NEW.id, NEW.title, NEW.body, NEW.country, NEW.city);
      END;
    SQL

    # Creating trigger post_fts_delete
    execute <<~SQL
      CREATE TRIGGER post_fts_delete AFTER DELETE ON posts
      BEGIN
        INSERT INTO post_fts (rowid, title, body, country, city)
        VALUES (OLD.id, NULL, NULL, NULL, NULL);
      END;
    SQL

    # Migrate existing post data
    Post.includes(:rich_text_body).find_each do |post|
      # Fallback to empty strings if any field is nil
      title   = post.title.presence || ""
      country = post.country.presence || ""
      city    = post.city.presence || ""

      # Ensure ActionText body is present and sanitized
      sanitized_body = ActionView::Base.full_sanitizer.sanitize(post.body&.to_s || "")

      execute <<~SQL
        INSERT INTO post_fts (rowid, title, body, country, city)
        VALUES (
          #{post.id},
          #{ActiveRecord::Base.connection.quote(title)},
          #{ActiveRecord::Base.connection.quote(sanitized_body)},
          #{ActiveRecord::Base.connection.quote(country)},
          #{ActiveRecord::Base.connection.quote(city)}
        );
      SQL
    end
  end

  def down
    execute "DROP TABLE IF EXISTS post_fts;"
    execute "DROP TRIGGER IF EXISTS post_fts_insert;"
    execute "DROP TRIGGER IF EXISTS post_fts_update;"
    execute "DROP TRIGGER IF EXISTS post_fts_delete;"
  end
end
