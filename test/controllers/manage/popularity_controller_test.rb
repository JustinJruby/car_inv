require "test_helper"

# Staff ranking of cars by active favorites (spec 006, US1, T014).
class Manage::PopularityControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  # Gives a car a number of active favorites, each from a different visitor, saved at the given time.
  def favorite_car(car, count, saved_at: Time.current)
    count.times do
      Favorite.create!(car: car, visitor_id: SecureRandom.uuid, saved_at: saved_at)
    end
  end

  test "signed-out visitors are sent to sign-in" do
    sign_out
    get manage_popularity_path
    assert_redirected_to new_session_path
  end

  test "cars are ordered most favorited first, with each count" do
    favorite_car(cars(:toyota), 3)
    favorite_car(cars(:subaru_reserved), 1)
    favorite_car(cars(:honda_sold), 2)

    get manage_popularity_path
    assert_response :success
    body = response.body
    assert_operator body.index("2021 Toyota RAV4"), :<, body.index("2019 Honda Civic")
    assert_operator body.index("2019 Honda Civic"), :<, body.index("2020 Subaru Outback")
  end

  test "a removed favorite does not count" do
    favorite_car(cars(:toyota), 1)
    Favorite.create!(car: cars(:subaru_reserved), visitor_id: SecureRandom.uuid, saved_at: Time.current, removed_at: Time.current)

    get manage_popularity_path
    assert_no_match "No favorites yet", response.body
    assert_includes Favorite.ranking(window: :all).map(&:first), cars(:toyota)
    assert_not_includes Favorite.ranking(window: :all).map(&:first), cars(:subaru_reserved)
  end

  test "shows the empty message when no car has favorites" do
    get manage_popularity_path
    assert_response :success
    assert_includes response.body, "No favorites yet"
  end

  test "sold cars still appear in the ranking with their status" do
    favorite_car(cars(:honda_sold), 2)
    get manage_popularity_path
    assert_includes response.body, "2019 Honda Civic"
    assert_includes response.body, "sold"
  end

  test "ties are ordered by make, then model" do
    favorite_car(cars(:toyota), 2)
    favorite_car(cars(:honda_sold), 2)

    get manage_popularity_path
    assert_operator response.body.index("2019 Honda Civic"), :<, response.body.index("2021 Toyota RAV4")
  end

  test "the 30-day window counts only active favorites saved in the last 30 days" do
    favorite_car(cars(:toyota), 1, saved_at: 3.days.ago)
    favorite_car(cars(:honda_sold), 4, saved_at: 60.days.ago)

    get manage_popularity_path, params: { window: "30" }
    assert_includes response.body, "2021 Toyota RAV4"
    assert_no_match "2019 Honda Civic", response.body
  end

  test "the default window is all time" do
    favorite_car(cars(:honda_sold), 4, saved_at: 60.days.ago)
    get manage_popularity_path
    assert_includes response.body, "2019 Honda Civic"
  end
end
