require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home explains the product and links visitors to sign up and explore" do
    get root_url

    assert_response :success
    assert_select "h1", text: "Share your trip as it unfolds."
    assert_select "picture source[srcset*='new-hero-image-']"
    assert_select "picture img[src*='new-hero-image-wide-']"
    assert_select "a[href='#{sign_up_path}']", minimum: 2
    assert_select "a[href='#{trips_path}']", minimum: 2
  end

  test "home links signed in users to trip creation" do
    sign_in_as users(:lazaro_nixon)

    get root_url

    assert_response :success
    assert_select "a[href='#{new_trip_path}']", minimum: 2
  end
end
