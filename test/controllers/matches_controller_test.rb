require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
    setup do
        @match = matches(:match_3)
        @tournament = @match.tournament
        @user = @tournament.user
    end

    test "Start a match" do
        log_in_as(@user)
        assert logged_in?

        assert_changes -> { Match.find(@match.id).underway_at } do
            post start_user_tournament_match_url(@user, @tournament, @match)
        end

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

    test "Try to update the score of a match, with an API failure" do
        log_in_as(@user)
        assert logged_in?

        url = get_api_url("#{@match.tournament.challonge_id}/matches/" \
                            "#{@match.challonge_id}.json")

        # The API key and other params are in the body of the request, not the
        # query string.
        stub_request(:put, url).to_return(make_api_error_response)

        assert_no_difference [ -> { @match.reload.team_score(:left) },
                               -> { @match.reload.team_score(:right) } ] do
            put user_tournament_match_url(@user, @tournament, @match,
                                          left_score: 2, right_score: 1)
        end

        assert_redirected_to user_tournament_path(@user, @tournament)
        assert_not flash.empty?
    end

    test "Try to start a non-existant match" do
        log_in_as(@user)
        assert logged_in?

        post start_user_tournament_match_url(@user, @tournament, Match.ids.max + 1)
        assert_response :not_found
    end
end
