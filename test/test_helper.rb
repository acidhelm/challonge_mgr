require "coveralls"

Coveralls.wear!

require "simplecov"

SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
require "rails/test_help"

VCR.configure do |config|
    config.cassette_library_dir = "test/vcr_cassettes"
    config.debug_logger = File.new("log/test_vcr.log", "a")
    config.ignore_localhost = true
    config.default_cassette_options = {
        record: :new_episodes,
        re_record_interval: Rails.configuration.vcr_re_record_time }
    config.hook_into :webmock
end

class ActiveSupport::TestCase
    # Set up all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Returns true if a test user is logged in.
    def logged_in?
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
