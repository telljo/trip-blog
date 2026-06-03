require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  setup do
    @post = posts(:one)
    @trip = @post.trip
    @user = @post.user
  end

  test "visiting the index" do
    visit posts_url
    assert_selector "h1", text: "Posts"
  end

  test "should create post" do
    sign_in_as @user
    visit new_trip_post_url(@trip)

    fill_in "Title", with: "A new post"
    find("trix-editor").set("A new post body")
    click_on "Create Post"

    assert_text "Post was successfully created"
    assert_current_path trip_path(@trip)
  end

  test "should update Post" do
    sign_in_as @user
    visit edit_post_url(@post)

    fill_in "Title", with: "Updated post"
    find("trix-editor").set("Updated post body")
    click_on "Update Post"

    assert_current_path trip_path(@trip)
    assert_text "Updated post"
  end

  test "should destroy Post" do
    sign_in_as @user
    visit post_url(@post)

    find("[aria-label='Edit Post']").click
    click_on "Delete post"

    assert_text "Post was successfully deleted"
  end
end
