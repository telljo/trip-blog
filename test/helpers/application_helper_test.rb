require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "carousel image loading options eagerly load hidden slides at low priority" do
    assert_equal(
      { decoding: "async", loading: "eager" },
      carousel_image_loading_options(0)
    )
    assert_equal(
      { decoding: "async", loading: "eager", fetchpriority: "low" },
      carousel_image_loading_options(1)
    )
  end
end
