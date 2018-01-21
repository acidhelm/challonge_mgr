require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
    setup do
        @tournament = tournaments(:one)
    end

    test "Get the tournaments index" do
        get user_tournaments_path(@tournament.user)
        assert_response :success
    end

    test "Show a tournament" do
        get user_tournament_path(@tournament.user, @tournament)
        assert_response :success
    end

    test "Get the tournament settings page" do
        get edit_user_tournament_path(@tournament.user, @tournament)
        assert_response :success
    end

    test "Update a tournament" do
        patch user_tournament_path(@tournament.user, @tournament), params: { tournament: { challonge_id: @tournament.challonge_id, challonge_url: @tournament.challonge_url, description: @tournament.description, name: @tournament.name, state: @tournament.state, user_id: @tournament.user_id } }
        assert_redirected_to user_tournament_path(@tournament.user, @tournament)
    end
end
