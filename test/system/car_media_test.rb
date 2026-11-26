require "application_system_test_case"

class CarMediaSystemTest < ApplicationSystemTestCase
  test "a description and feature tag entered by staff appear for customers" do
    sign_in_staff_in_browser

    visit edit_manage_car_path(cars(:toyota))
    find("trix-editor").click.send_keys("Garage kept, one owner")
    fill_in "car[feature_names]", with: "sunroof"
    click_button "Update Car"
    assert_text "Car updated."

    page.driver.browser.manage.delete_all_cookies
    visit car_path(cars(:toyota))
    assert_text "Garage kept, one owner"

    visit cars_path(feature: "sunroof")
    assert_text "2021 Toyota RAV4"
  end
end
