require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trip = trips(:one)
    @post = posts(:one)
  end

  test "should get sitemap" do
    get "/sitemap.xml"

    assert_response :success
    assert_equal "application/xml", response.media_type
  end

  test "sitemap includes public trips and published posts" do
    get "/sitemap.xml"

    locations = sitemap_locations
    assert_includes locations, trip_url(@trip)
    assert_includes locations, post_url(@post)
  end

  test "sitemap excludes hidden and draft posts" do
    hidden_post = posts(:one)
    draft_post = posts(:two)
    hidden_post.update!(hidden: true)
    draft_post.update!(draft: true)

    get "/sitemap.xml"

    locations = sitemap_locations
    assert_not_includes locations, post_url(hidden_post)
    assert_not_includes locations, post_url(draft_post)
  end

  test "robots txt points to sitemap" do
    assert_includes Rails.root.join("public/robots.txt").read, "Sitemap: https://footprints.fly.dev/sitemap.xml"
  end

  private

  def sitemap_locations
    Nokogiri::XML(response.body).xpath("//*[local-name()='loc']").map(&:text)
  end
end
