require "application_system_test_case"

class FavoritesSystemTest < ApplicationSystemTestCase
  test "a customer saves a car, sees it after reload, and loses it after clearing storage" do
    car = cars(:toyota)

    visit car_path(car)
    assert_button "Save to favorites"
    click_button "Save to favorites"
    assert_button "Remove from favorites"

    visit favorites_path
    assert_text "2021 Toyota RAV4"

    visit favorites_path
    assert_text "2021 Toyota RAV4"

    execute_script("window.localStorage.clear()")
    visit favorites_path
    assert_text "You have no saved cars"
  end

  test "a price reduction shows a badge once, then the badge clears on the next visit" do
    car = cars(:toyota)

    visit car_path(car)
    assert_button "Save to favorites"
    click_button "Save to favorites"

    car.update!(asking_price: "21000.00")

    visit favorites_path(ids: car.id)
    assert_text "Price dropped", wait: 5

    visit favorites_path(ids: car.id)
    assert_no_text "Price dropped"
  end
end
