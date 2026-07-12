require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "carousel image loading options eagerly load first slide and queue hidden slides" do
    assert_equal(
      { decoding: "async", loading: "eager" },
      carousel_image_loading_options(0)
    )
    assert_equal(
      {
        data: { carousel_preload: true },
        decoding: "async",
        fetchpriority: "low",
        loading: "lazy"
      },
      carousel_image_loading_options(1)
    )
  end
end
