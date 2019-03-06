require "simplecov"
require "coveralls"
require 'webmock/minitest'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [ SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter ])

SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
require "rails/test_help"

VCR.configure do |config|
    config.cassette_library_dir = "test/vcr_cassettes"
    config.debug_logger = File.new("log/test_vcr.log", "a")
    config.ignore_localhost = true
    config.ignore_hosts "kqchat.slack.com"
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

    # Returns a string that holds the URL to the Challonge API endpoint, with
    # `str` appended to it.  Since all API URLs start with "tournaments", the
    # caller should not include that in `str`.  Omitting `str` will return the
    # URL for the "tournaments.json" endpoint.
    # TODO: Figure out if we can share this code with `ChallongeHelper`.
    def get_api_url(str = nil)
        base_url = "https://api.challonge.com/v1/tournaments"

        return str ? "#{base_url}/#{str}" : "#{base_url}.json"
    end

    # Returns a hash that indicates a Challonge API failure.  This can be
    # passed to WebMock's `to_return` method.
    def make_api_error_response(status: 500, message: "Server error")
        body = { errors: [ message ] }.to_json

        return { status: status, body: body }
    end
end

class ActionDispatch::IntegrationTest
    def log_in_as(user, password = "password")
        post login_path, params: { session: { user_name: user.user_name,
                                              password: password } }

        assert_redirected_to user_tournaments_refresh_path(user)
    end
end
