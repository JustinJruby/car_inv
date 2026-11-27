require "application_system_test_case"

# Favorites are saved on the server for the visitor's cookie (spec 006, T010).
class FavoritesSystemTest < ApplicationSystemTestCase
  test "a customer saves a car, sees it after reload, removes it, and loses it when the visitor cookie is cleared" do
    car = cars(:toyota)

    visit car_path(car)
    assert_button "Save to favorites"
    click_button "Save to favorites"
    assert_button "Remove from favorites"

    visit favorites_path
    assert_text "2021 Toyota RAV4"

    visit favorites_path
    assert_text "2021 Toyota RAV4"

    visit car_path(car)
    assert_button "Remove from favorites"
    click_button "Remove from favorites"
    assert_button "Save to favorites"

    visit favorites_path
    assert_text "You have no saved cars"

    visit car_path(car)
    click_button "Save to favorites"
    assert_button "Remove from favorites"

    page.driver.browser.manage.delete_all_cookies
    visit favorites_path
    assert_text "You have no saved cars"
  end

  test "a price reduction shows a badge once, then the badge clears on the next visit" do
    car = cars(:toyota)

    visit car_path(car)
    assert_button "Save to favorites"
    click_button "Save to favorites"
    assert_button "Remove from favorites"  # wait for the server to confirm the save

    car.update!(asking_price: "21000.00")

    visit favorites_path
    assert_text "Price dropped", wait: 5

    visit favorites_path
    assert_no_text "Price dropped"
  end
end
