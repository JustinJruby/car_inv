require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end

class SessionsThrottleTest < ActionDispatch::IntegrationTest
  setup { Rails.cache.clear }

  test "sign-in attempts are throttled per email address" do
    11.times { post session_path, params: { email_address: "one@example.com", password: "wrong" } }

    assert_redirected_to new_session_path
    assert_equal "Try again later.", flash[:alert]
  end

  test "throttling one email does not block another" do
    11.times { post session_path, params: { email_address: "one@example.com", password: "wrong" } }
    post session_path, params: { email_address: "two@example.com", password: "password" }

    assert_redirected_to root_path
  end
end
