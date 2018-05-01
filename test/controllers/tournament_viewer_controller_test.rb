require "test_helper"

class TournamentViewerControllerTest < ActionDispatch::IntegrationTest
    setup do
        @tournament = tournaments(:one)
    end

    test "View a tournament" do
        get view_tournament_path(@tournament.challonge_alphanumeric_id)
        assert_response :success
    end

    test "View a tournament's gold team name" do
        get view_tournament_gold_path(@tournament.challonge_alphanumeric_id)
        assert_response :success
    end

    test "View a tournament's blue team name" do
        get view_tournament_blue_path(@tournament.challonge_alphanumeric_id)
        assert_response :success
    end

    test "View a tournament's gold team score" do
        get view_tournament_gold_score_path(@tournament.challonge_alphanumeric_id)
        assert_response :success
    end

    test "View a tournament's blue team score" do
        get view_tournament_blue_score_path(@tournament.challonge_alphanumeric_id)
        assert_response :success
    end
end
