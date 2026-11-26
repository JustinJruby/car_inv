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
end
