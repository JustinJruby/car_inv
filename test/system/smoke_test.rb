require "application_system_test_case"

class SmokeTest < ApplicationSystemTestCase
  test "public inventory page loads in a browser" do
    visit cars_path
    assert_text "Available cars"
  end
end
