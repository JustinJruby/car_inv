require "test_helper"

# Spec 006: no personal detail is stored with a favorite (FR-002, SC-003), the visitor cookie is
# signed and httponly (research R2), and customer pages never show a count or ranking (FR-004, SC-004).
class FavoritePrivacyTest < ActionDispatch::IntegrationTest
  test "a stored favorite holds no personal detail" do
    columns = Favorite.column_names
    assert_equal %w[id car_id visitor_id saved_at removed_at created_at updated_at].sort, columns.sort
    assert_empty columns & %w[name email phone address ip_address user_agent]
  end

  test "the visitor cookie is signed and httponly" do
    post car_favorite_path(cars(:toyota))
    header = response.headers["Set-Cookie"]
    assert_match(/visitor_id=/, header)
    assert_match(/httponly/i, header)
  end

  test "customer pages show no favorite count or ranking" do
    post car_favorite_path(cars(:toyota))

    [ cars_path, car_path(cars(:toyota)), favorites_path ].each do |path|
      get path
      assert_response :success
      assert_no_match "Car popularity", response.body
      assert_no_match "Favorites:", response.body
      assert_no_match(/\d+ favorites?/, response.body)
    end
  end

  test "the car page does not reveal how many visitors saved the car" do
    Favorite.create!(car: cars(:toyota), visitor_id: SecureRandom.uuid, saved_at: Time.current)
    get car_path(cars(:toyota))
    assert_response :success
    assert_no_match "1 favorite", response.body
    assert_no_match "saved by", response.body
  end
end
