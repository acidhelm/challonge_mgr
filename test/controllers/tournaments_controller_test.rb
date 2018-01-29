require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
    setup do
        @tournament = tournaments(:one)
        @user = @tournament.user
        @other_tournament = tournaments(:two)
        @other_user = @other_tournament.user
    end

    test "Get the tournaments index" do
        log_in_as(@user)
        assert is_logged_in?

        get user_tournaments_path(@user)
        assert_response :success
    end

    test "Try to get the tournaments index for a different user" do
        log_in_as(@user)
        assert is_logged_in?

        get user_tournaments_path(@other_user)
        assert_response :forbidden
    end

    test "Try to get the tournaments index without logging in" do
        get user_tournaments_path(@user)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Show a tournament" do
        log_in_as(@user)
        assert is_logged_in?

        get user_tournament_path(@user, @tournament)
        assert_response :success
    end

    test "Try to show a tournament for a different user" do
        log_in_as(@user)
        assert is_logged_in?

        get user_tournament_path(@other_user, @other_tournament)
        assert_response :forbidden
    end

    test "Try to show a tournament without logging in" do
        get user_tournament_path(@user, @tournament)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Get the tournament settings page" do
        log_in_as(@user)
        assert is_logged_in?

        get edit_user_tournament_path(@user, @tournament)
        assert_response :success
    end

    test "Try to get the tournament settings page for a different user" do
        log_in_as(@user)
        assert is_logged_in?

        get edit_user_tournament_path(@other_user, @other_tournament)
        assert_response :forbidden
    end

    test "Try to get the tournament settings page without logging in" do
        get edit_user_tournament_path(@user, @tournament)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Update a tournament" do
        log_in_as(@user)
        assert is_logged_in?

        patch user_tournament_path(@user, @tournament),
                params: {
                  tournament: {
                    gold_on_left: @tournament.gold_on_left,
                    send_slack_notifications: @tournament.send_slack_notifications,
                    slack_notifications_channel: @tournament.slack_notifications_channel } }

        assert_redirected_to user_tournament_path(@user, @tournament)
    end

    test "Try to update a tournament for a different user" do
        log_in_as(@user)
        assert is_logged_in?

        patch user_tournament_path(@other_user, @other_tournament),
                params: {
                  tournament: {
                    gold_on_left: @other_tournament.gold_on_left,
                    send_slack_notifications: @other_tournament.send_slack_notifications,
                    slack_notifications_channel: @other_tournament.slack_notifications_channel } }

        assert_response :forbidden
    end

    test "Try to update a tournament without logging in" do
        patch user_tournament_path(@user, @tournament),
                params: {
                  tournament: {
                    gold_on_left: @tournament.gold_on_left,
                    send_slack_notifications: @tournament.send_slack_notifications,
                    slack_notifications_channel: @tournament.slack_notifications_channel } }

        assert_redirected_to login_url
        assert_not flash.empty?
    end
end
