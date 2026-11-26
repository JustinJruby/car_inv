require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "shows saved cars without signing in" do
    get favorites_path, params: { ids: cars(:toyota).id }
    assert_response :success
    assert_includes response.body, "Toyota"
  end

  test "marks a sold car as no longer available" do
    get favorites_path, params: { ids: cars(:honda_sold).id }
    assert_includes response.body, "no longer available"
  end

  test "marks a missing car as no longer listed" do
    get favorites_path, params: { ids: 999_999 }
    assert_includes response.body, "no longer listed"
  end

  test "ignores malformed ids" do
    get favorites_path, params: { ids: "abc,," }
    assert_response :success
    assert_includes response.body, "You have no saved cars"
  end
end
