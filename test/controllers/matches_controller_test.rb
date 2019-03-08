require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
    setup do
        @match = matches(:match_3)
        @tournament = @match.tournament
        @user = @tournament.user
    end

    def make_challonge_attrs(match)
        attrs = match.attributes

        # These attributes use "team" in their names, but Challonge uses "player".
        %w(team1_id team2_id team1_prereq_match_id team2_prereq_match_id
           team1_is_prereq_match_loser team2_is_prereq_match_loser).each do |attr|
            attrs[attr.sub("team", "player")] = attrs.delete(attr)
        end

        return { match: attrs }.with_indifferent_access
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

    test "Update the score and winner of a match" do
        log_in_as(@user)
        assert logged_in?

        post start_user_tournament_match_url(@user, @tournament, @match)

        url = get_api_url("#{@match.tournament.challonge_id}/matches/" \
                            "#{@match.challonge_id}.json")

        # The controller uses the JSON that Challonge returns from the update
        # call, so we need to build some JSON in that format.
        left_score = 3
        right_score = 1
        attrs = make_challonge_attrs(@match)

        # Since we're setting `scores_csv` manually, we have to do the same
        # test that `Match#make_scores_csv` does to check if the teams have
        # switched sides.
        attrs[:match][:scores_csv] = if @match.get_team_id(:left) == @match.team1_id
                                         "#{left_score}-#{right_score}"
                                     else
                                         "#{right_score}-#{left_score}"
                                     end

        # The API key and other params are in the body of the request, not the
        # query string.
        stub_request(:put, url).to_return(body: attrs.to_json)

        put user_tournament_match_url(@user, @tournament, @match,
                                      left_score: left_score, right_score: right_score)

        @match.reload

        assert_equal left_score, @match.team_score(:left)
        assert_equal right_score, @match.team_score(:right)

        assert_redirected_to user_tournament_path(@user, @tournament)
        assert flash.empty?

        # Set the winning team.
        attrs = make_challonge_attrs(@match)

        attrs[:match][:state] = "complete"
        attrs[:match][:winner_id] = @match.get_team_id(:left)
        attrs[:match][:loser_id] = @match.get_team_id(:right)

        stub_request(:put, url).to_return(body: attrs.to_json)

        put user_tournament_match_url(@user, @tournament, @match,
                                      winner_id: @match.get_team_id(:left))

        @match.reload

        assert @match.team_won?(:left)
        assert_not @match.team_won?(:right)
        assert_equal left_score, @match.team_score(:winner)
        assert_equal right_score, @match.team_score(:loser)

        assert_redirected_to refresh_user_tournament_path(@user, @tournament, get_teams: 0)
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
