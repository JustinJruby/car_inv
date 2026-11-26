require "test_helper"

class UiLayoutTest < ActionDispatch::IntegrationTest
  test "pages include the compiled Tailwind stylesheet and public navigation" do
    get cars_path

    assert_response :success
    assert_select "link[rel=stylesheet][href*=tailwind]"
    assert_select "header nav a[href=?]", cars_path, text: "Inventory"
    assert_select "header nav a[href=?]", new_session_path, text: "Staff sign in"
    assert_select "header nav a[href=?]", manage_cars_path, count: 0
  end

  test "signed-in staff see manage and sign out navigation" do
    sign_in_as users(:one)

    get cars_path

    assert_response :success
    assert_select "header nav a[href=?]", manage_cars_path, text: "Manage cars"
    assert_select "header nav button", text: "Sign out"
    assert_select "header nav a[href=?]", new_session_path, count: 0
  end

  # Favorites header link (spec 005, US1, T001).
  test "signed-out visitors see a Favorites link next to Inventory" do
    get cars_path

    assert_response :success
    assert_select "header nav a[href=?]", favorites_path, text: "Favorites"
    assert_select "header nav a", text: "Inventory"
  end

  test "signed-in staff also see the Favorites link alongside Inventory and Manage cars" do
    sign_in_as users(:one)

    get cars_path

    assert_response :success
    assert_select "header nav a[href=?]", favorites_path, text: "Favorites"
    assert_select "header nav a[href=?]", cars_path, text: "Inventory"
    assert_select "header nav a[href=?]", manage_cars_path, text: "Manage cars"
  end
end
