require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
    setup do
        @match = matches(:three)
        @tournament = @match.tournament
        @user = @tournament.user
    end

    test "Start a match" do
        log_in_as(@user)
        assert is_logged_in?

        post start_user_tournament_match_url(@user, @tournament, @match)
        assert_redirected_to user_tournament_path(@user, @tournament)
    end
end
