require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @trip = trips(:one)
    @user = users(:lazaro_nixon)
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get new" do
    sign_in_as @user

    get new_trip_post_url(@trip)
    assert_response :success
    assert_select "form[data-controller='direct-uploads'][data-direct-uploads-concurrency-value='3']"
    assert_select "input[type='file'][data-action='change->direct-uploads#upload'][data-direct-upload-url]"
  end

  test "should create post" do
    sign_in_as @user

    assert_difference("Post.count") do
      post trip_posts_url(@trip), params: { post: { title: "New post", body: "New post body" } }
    end

    assert_redirected_to trip_url(@trip)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    sign_in_as @user

    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    sign_in_as @user

    patch post_url(@post), params: { post: { title: "Updated post" } }
    assert_redirected_to trip_url(@post.trip)
  end

  test "should destroy post" do
    sign_in_as @user

    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to trip_url(@post.trip)
  end
end
