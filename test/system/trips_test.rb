require "application_system_test_case"

class TripsTest < ApplicationSystemTestCase
  setup do
    @trip = trips(:one)
    @user = @trip.user
  end

  test "visiting the index" do
    visit trips_url
    assert_selector "h1", text: "Trips"
    assert_selector ".trip-preview-card", minimum: 2
  end

  test "trip post pagination advances the url and updates the current page" do
    5.times do |index|
      @trip.posts.create!(
        title: "Pagination post #{index + 1}",
        body: "Pagination post body #{index + 1}",
        user: @user,
        created_at: (index + 1).minutes.ago
      )
    end

    visit trip_url(@trip)

    within "turbo-frame#trip-posts-page" do
      first("a.page-link", text: "2").click
    end

    assert_current_path trip_path(@trip, page: 2)
    assert_selector "turbo-frame#trip-posts-page a.page-link[aria-current='page']", text: "2"

    page.refresh

    assert_current_path trip_path(@trip, page: 2)
    assert_selector "turbo-frame#trip-posts-page a.page-link[aria-current='page']", text: "2"
  end

  test "should create trip" do
    sign_in_as @user
    visit trips_url
    click_on "Create new trip"

    fill_in "trip_name", with: "A new trip"
    find("trix-editor").set("A new trip body")
    click_on "Create Trip"

    assert_text "Trip was successfully created"
    assert_text "A new trip"
  end

  test "should update Trip" do
    sign_in_as @user
    visit edit_trip_url(@trip)

    fill_in "trip_name", with: "Updated trip"
    find("trix-editor").set("Updated trip body")
    click_on "Update Trip"

    assert_text "Trip was successfully updated"
    assert_text "Updated trip"
  end

  test "should destroy Trip" do
    sign_in_as @user
    visit trip_url(@trip)

    find("[aria-label='Edit trip']", match: :first).click
    click_on "Delete trip"

    assert_text "Trip was successfully destroyed"
  end
end
