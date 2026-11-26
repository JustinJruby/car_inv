require "application_system_test_case"

class FavoritesHeaderSystemTest < ApplicationSystemTestCase
  # Spec 005, US1, T002: the header link opens the favorites page.
  test "a visitor clicks Favorites in the header and lands on the favorites page" do
    visit root_path
    within "header" do
      click_link "Favorites"
    end
    assert_current_path favorites_path
    assert_text "Saved cars"
  end
end
