require "test_helper"

class TripsHelperTest < ActionView::TestCase
  test "posts pagination nav adds descriptive labels to page links" do
    pagy = Struct.new(:captured_options) do
      def series_nav(style, **options)
        self.captured_options = { style: style, options: options }

        <<~HTML
          <nav class="pagy-bootstrap series-nav" aria-label="Pages">
            <ul class="pagination">
              <li class="page-item"><a href="/trips/1?page=1" class="page-link" rel="prev">&lt;</a></li>
              <li class="page-item"><a href="/trips/1?page=1" class="page-link">1</a></li>
              <li class="page-item active"><a role="link" class="page-link" aria-current="page" aria-disabled="true">2</a></li>
              <li class="page-item gap disabled"><a role="link" class="page-link" aria-disabled="true">&hellip;</a></li>
              <li class="page-item"><a href="/trips/1?page=3" class="page-link" rel="next">&gt;</a></li>
            </ul>
          </nav>
        HTML
      end
    end.new

    html = posts_pagination_nav(pagy)
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal :bootstrap, pagy.captured_options[:style]
    assert_equal 'data-turbo-frame="trip-posts-page" data-turbo-action="advance"', pagy.captured_options[:options][:anchor_string]
    assert_equal "Posts pages", pagy.captured_options[:options][:aria_label]

    labels = fragment.css("a.page-link").map { |link| link["aria-label"] }
    assert_includes labels, "Go to previous posts page"
    assert_includes labels, "Go to posts page 1"
    assert_includes labels, "Current posts page, page 2"
    assert_includes labels, "More posts pages"
    assert_includes labels, "Go to next posts page"
  end
end
