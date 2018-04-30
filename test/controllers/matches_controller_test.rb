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

        # We need to re-read the `Tournament` object from the database to
        # get the updated value of `current_match`.
        assert_equal @match.id, Tournament.find(@tournament.id).current_match
    end

    test "Switch the sides of teams in a match" do
        log_in_as(@user)
        assert is_logged_in?

        post switch_user_tournament_match_url(@user, @tournament, @match)
        assert_redirected_to user_tournament_path(@user, @tournament)

        # We need to re-read the `Match` object from the database to
        # get the updated team IDs.
        new_match = Match.find(@match.id)

        assert_equal @match.blue_team_id, new_match.gold_team_id
        assert_equal @match.gold_team_id, new_match.blue_team_id
    end
end
