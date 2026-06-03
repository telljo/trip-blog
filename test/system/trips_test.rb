require "application_system_test_case"

class TripsTest < ApplicationSystemTestCase
  setup do
    @trip = trips(:one)
    @user = @trip.user
  end

  test "visiting the index" do
    visit trips_url
    assert_selector "h2", text: "Trips"
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
