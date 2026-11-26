require "application_system_test_case"

class LiveUpdatesTest < ApplicationSystemTestCase
  test "a status change appears on another open staff screen without a manual reload" do
    car = cars(:toyota)

    using_session(:viewer) do
      sign_in_staff_in_browser
      visit manage_cars_path
      assert_selector "turbo-cable-stream-source[connected]", visible: :all, wait: 5
      assert_text "available"
    end

    using_session(:editor) do
      sign_in_staff_in_browser
      visit edit_manage_car_path(car)
      select "Reserved", from: "car[status]"
      click_button "Update Car"
      assert_text "Car updated."
    end

    using_session(:viewer) do
      assert_text "reserved", wait: 5
    end
  end
end
