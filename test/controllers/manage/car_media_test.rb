require "test_helper"

class Manage::CarMediaTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @car = cars(:toyota)
  end

  def photo(name = "photo.png", type = "image/png")
    fixture_file_upload(name, type)
  end

  test "attaches a photo and shows it in the customer gallery" do
    patch manage_car_path(@car), params: { car: { new_photos: [ photo ] } }
    assert_redirected_to manage_cars_path
    assert_equal 1, @car.reload.photos.count

    get car_path(@car)
    assert_includes response.body, "gallery"
  end

  test "uploading more photos adds to the gallery instead of replacing it" do
    patch manage_car_path(@car), params: { car: { new_photos: [photo] } }
    patch manage_car_path(@car), params: { car: { new_photos: [photo] } }
    assert_equal 2, @car.reload.photos.count
  end

  test "rejects a non-image file and keeps existing photos" do
    patch manage_car_path(@car), params: { car: { new_photos: [ photo ] } }
    assert_equal 1, @car.reload.photos.count

    patch manage_car_path(@car), params: { car: { new_photos: [ photo("notes.txt", "text/plain") ] } }
    assert_response :unprocessable_entity
    assert_equal 1, @car.reload.photos.count
  end

  test "saves tags from a comma separated list and applies them to the car" do
    patch manage_car_path(@car), params: { car: { feature_names: "Sunroof, leather seats" } }
    assert_equal %w[leather\ seats sunroof], @car.reload.features.map(&:name).sort
  end

  test "rich text description appears on the customer page" do
    patch manage_car_path(@car), params: { car: { description: "<strong>Garage kept</strong>" } }
    get car_path(@car)
    assert_includes response.body, "<strong>Garage kept</strong>"
  end

  test "editing a photo touches the car so it counts as an edit" do
    travel_to 1.hour.from_now do
      patch manage_car_path(@car), params: { car: { new_photos: [ photo ] } }
    end
    assert_in_delta Time.current, @car.reload.updated_at, 1.day
  end
end
