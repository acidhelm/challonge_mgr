require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
    driven_by :selenium, using: :chrome, screen_size: [800, 1000]

    def take_failed_screenshot
        false
    end

    def log_in_as(user, password = "password")
        visit login_url

        fill_in :user_name, with: user.user_name
        fill_in :password, with: password

        VCR.use_cassette("get_tournament_list") do
            click_on "Log in"
            assert_current_path(user_tournaments_path(user))
        end
    end
end
