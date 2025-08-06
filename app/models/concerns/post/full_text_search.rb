module Post::FullTextSearch
  extend ActiveSupport::Concern

  included do
    has_one :post_fts, foreign_key: "rowid"
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
