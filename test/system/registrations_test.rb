require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "signing up" do
    visit sign_up_url

    fill_in "Username", with: "lazaro_new"
    fill_in "Email", with: "lazaronixon@hey.com"
    fill_in "Password", with: "Secret6*4*2*"
    fill_in "Password confirmation", with: "Secret6*4*2*"
    within "form" do
      click_on "Sign up"
    end

    assert_text "Welcome! You have signed up successfully"
  end
end
