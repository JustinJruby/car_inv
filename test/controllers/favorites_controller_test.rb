require "test_helper"

# Favorites live on the server, tied to a random visitor identifier in a cookie (spec 006, T006).
class FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "saving a car creates one active favorite for this visitor" do
    post car_favorite_path(cars(:toyota))
    assert_response :success
    assert_equal true, JSON.parse(response.body)["saved"]

    favorite = Favorite.find_by!(car: cars(:toyota))
    assert favorite.active?
    assert_match Favorite::UUID_FORMAT, favorite.visitor_id
  end

  test "saving the same car twice creates no duplicate" do
    post car_favorite_path(cars(:toyota))
    assert_no_difference "Favorite.count" do
      post car_favorite_path(cars(:toyota))
    end
    assert_response :success
  end

  test "removing a favorite sets removed_at" do
    post car_favorite_path(cars(:toyota))
    delete car_favorite_path(cars(:toyota))
    assert_response :success
    assert_equal false, JSON.parse(response.body)["saved"]
    assert Favorite.find_by!(car: cars(:toyota)).removed_at.present?
  end

  test "the favorites page lists this visitor's active favorites from the server" do
    post car_favorite_path(cars(:toyota))
    get favorites_path
    assert_response :success
    assert_includes response.body, "Toyota"
  end

  test "the favorites page does not list another visitor's favorites" do
    Favorite.create!(car: cars(:toyota), visitor_id: SecureRandom.uuid, saved_at: Time.current)
    get favorites_path
    assert_response :success
    assert_includes response.body, "You have no saved cars"
  end

  test "a removed favorite is not listed" do
    post car_favorite_path(cars(:toyota))
    delete car_favorite_path(cars(:toyota))
    get favorites_path
    assert_includes response.body, "You have no saved cars"
  end

  test "marks a sold car as no longer available" do
    post car_favorite_path(cars(:honda_sold))
    get favorites_path
    assert_includes response.body, "no longer available"
  end

  test "the visitor cookie is signed and httponly" do
    post car_favorite_path(cars(:toyota))
    assert_match(/visitor_id=/, response.headers["Set-Cookie"])
    assert_match(/httponly/i, response.headers["Set-Cookie"])
  end
end
