module Post::FullTextSearch
  extend ActiveSupport::Concern

  included do
    has_one :post_fts, foreign_key: "rowid"

    after_commit :sync_full_text_search
  end

  def sync_full_text_search
    sanitized_body = ActionView::Base.full_sanitizer.sanitize(self.body&.to_s || "")

    quoted_title   = ActiveRecord::Base.connection.quote(self.title.to_s.presence || "")
    quoted_body    = ActiveRecord::Base.connection.quote(sanitized_body)
    quoted_country = ActiveRecord::Base.connection.quote(self.country.to_s.presence || "")
    quoted_city    = ActiveRecord::Base.connection.quote(self.city.to_s.presence || "")

    sql = <<~SQL
      INSERT OR REPLACE INTO post_fts (rowid, title, body, country, city)
      VALUES (
        #{id},
        #{quoted_title},
        #{quoted_body},
        #{quoted_country},
        #{quoted_city}
      )
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end

  class_methods do
    def full_text_search(input:, trip: nil, posts: nil)
      return none if input.blank?

      # Add asterisk to the last word if not already there
      tokens = input.strip.split
      if tokens.any?
        tokens[-1] = "#{tokens[-1]}*" unless tokens[-1].end_with?("*")
        input = tokens.join(" ")
      end
      where(posts: posts)
      where(trip: trip)
      .joins("JOIN post_fts ON post_fts.rowid = posts.id")
        .where("post_fts MATCH ?", input)
        .order("bm25(post_fts) ASC")
        .distinct
    end
  end
end
