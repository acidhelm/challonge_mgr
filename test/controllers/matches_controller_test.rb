require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
    setup do
        @match = matches(:three)
        @tournament = @match.tournament
        @user = @tournament.user
    end

    test "Start a match" do
        log_in_as(@user)
        assert logged_in?

        post start_user_tournament_match_url(@user, @tournament, @match)
        assert_redirected_to user_tournament_path(@user, @tournament)

        # We need to re-read the `Tournament` object from the database to
        # get the updated value of `current_match`.
        assert_equal @match.id, Tournament.find(@tournament.id).current_match
    end

    test "Try to start a match without logging in" do
        post start_user_tournament_match_url(@user, @tournament, @match)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Switch the sides of the teams in a match" do
        log_in_as(@user)
        assert logged_in?

        post switch_user_tournament_match_url(@user, @tournament, @match)
        assert_redirected_to user_tournament_path(@user, @tournament)

        # We need to re-read the `Match` object from the database to
        # get the updated team IDs.
        new_match = Match.find(@match.id)

        assert_equal @match.blue_team_id, new_match.gold_team_id
        assert_equal @match.gold_team_id, new_match.blue_team_id
    end

    test "Try to switch the sides of the teams in a match without logging in" do
        post switch_user_tournament_match_url(@user, @tournament, @match)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Try to update the winner and scores of a match, passing invalid params" do
        log_in_as(@user)
        assert logged_in?

        put user_tournament_match_url(@user, @tournament, @match,
            winner_id: @match.team1_id, left_score: 1, right_score: 2)
        assert_response :bad_request

        put user_tournament_match_url(@user, @tournament, @match, left_score: 3)
        assert_response :bad_request

        put user_tournament_match_url(@user, @tournament, @match, right_score: 4)
        assert_response :bad_request
    end

    test "Try to start a non-existant match" do
        log_in_as(@user)
        assert logged_in?

        post start_user_tournament_match_url(@user, @tournament, Match.ids.max + 1)
        assert_response :not_found
    end
end
