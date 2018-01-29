require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"

class ActiveSupport::TestCase
    # Set up all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Returns true if a test user is logged in.
    def is_logged_in?
        return session[:user_id].present?
    end
end

class ActionDispatch::IntegrationTest
    def log_in_as(user, password = "password")
        post login_path, params: { session: { user_name: user.user_name,
                                              password: password } }

        assert_redirected_to user_tournaments_refresh_path(user)
    end
end
