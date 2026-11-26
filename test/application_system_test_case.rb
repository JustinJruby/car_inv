require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]

  setup do
    Rails.cache.clear
    # Start each test with no favorites and no cookies left from an earlier test.
    visit "/up"
    execute_script("window.localStorage.clear()")
    page.driver.browser.manage.delete_all_cookies
  end

  # Sign in through the real form and wait for the signed-in navigation, so later
  # steps never run before the session cookie is set.
  def sign_in_staff_in_browser(email: "one@example.com", password: "password")
    visit new_session_path
    fill_in "email_address", with: email
    fill_in "password", with: password
    click_button "Sign in"
    assert_button "Sign out"
  end

  # Capybara clears storage with origin "*", which current Chrome rejects. Tolerate
  # that one error and clear cookies directly so each test still starts clean.
  def after_teardown
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError
    page.driver.browser.manage.delete_all_cookies rescue nil
  end
end
