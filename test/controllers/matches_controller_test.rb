require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
    test "Start a match" do
        match = matches(:three)
        post start_user_tournament_match_url(match.tournament.user, match.tournament, match)
        assert_redirected_to user_tournament_path(match.tournament.user, match.tournament)
    end
end
