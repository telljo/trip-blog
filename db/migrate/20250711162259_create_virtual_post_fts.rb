class CreateVirtualPostFts < ActiveRecord::Migration[8.0]
  def up
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
  end
end
