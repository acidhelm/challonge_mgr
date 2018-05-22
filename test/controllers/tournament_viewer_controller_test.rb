require "test_helper"

class TournamentViewerControllerTest < ActionDispatch::IntegrationTest
    setup do
        @tournament = tournaments(:one)
        @slug = @tournament.challonge_alphanumeric_id
        @bad_slug = @slug.reverse
    end

    def team_names_in_match_test(team_name_url, match, side)
        # The team name action should return an empty string when no match has
        # been started yet.
        get team_name_url
        assert_response :success
        assert_empty response.body

        # Log in so we can start a match.
        log_in_as @tournament.user

        # Start the next match.
        post start_user_tournament_match_path(@tournament.user, @tournament, match)
        assert_response :redirect

        # Check that we're redirected to the right URL.
        assert_redirected_to user_tournament_path(@tournament.user, @tournament)

        follow_redirect!
        assert_response :success

        # The team name action should return a name now.
        get team_name_url
        assert_equal match.team_name(side), response.body
    end

    test "View a tournament" do
        [ @slug, @slug.upcase ].each do |id|
            get view_tournament_path(id)
            assert_response :success
        end
    end

    test "View a tournament's gold team name" do
        team_names_in_match_test(
            view_tournament_gold_path(@slug),
            @tournament.matches.upcoming.first, :gold)
    end

    test "View a tournament's blue team name" do
        team_names_in_match_test(
            view_tournament_blue_path(@slug),
            @tournament.matches.upcoming.first, :blue)
    end

    test "View a tournament's gold team score" do
        get view_tournament_gold_score_path(@slug)
        assert_response :success
        assert_equal "0", response.body
    end

    test "View a tournament's blue team score" do
        get view_tournament_blue_score_path(@slug)
        assert_response :success
        assert_equal "0", response.body
    end

    test "Try to view a non-existant tournament" do
        get view_tournament_path(@bad_slug)
        assert_response :not_found
    end

    test "Try to view a non-existant tournament's gold team name" do
        get view_tournament_gold_path(@bad_slug)
        assert_response :not_found
    end

    test "Try to view a non-existant tournament's blue team name" do
        get view_tournament_blue_path(@bad_slug)
        assert_response :not_found
    end

    test "Try to view a non-existant tournament's gold team score" do
        get view_tournament_gold_score_path(@bad_slug)
        assert_response :not_found
    end

    test "Try to view a non-existant tournament's blue team score" do
        get view_tournament_blue_score_path(@bad_slug)
        assert_response :not_found
    end
end
