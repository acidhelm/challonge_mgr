require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
    setup do
        @tournament = tournaments(:one)
        @user = @tournament.user
        @other_tournament = tournaments(:two)
        @other_user = @other_tournament.user
    end

    def update_tournament_params(tournament)
        return { tournament: {
                   gold_on_left: !tournament.gold_on_left,
                   send_slack_notifications: tournament.send_slack_notifications,
                   slack_notifications_channel: tournament.slack_notifications_channel } }
    end

    test "Get the tournaments index" do
        log_in_as(@user)
        assert logged_in?

        get user_tournaments_path(@user)
        assert_response :success
    end

    test "Try to get the tournaments index for a different user" do
        log_in_as(@user)
        assert logged_in?

        get user_tournaments_path(@other_user)
        assert_response :forbidden
    end

    test "Try to get the tournaments index for a non-existant user" do
        get user_tournaments_path(User.ids.max + 1)
        assert_response :not_found
    end

    test "Try to get the tournaments index without logging in" do
        get user_tournaments_path(@user)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Show a tournament" do
        log_in_as(@user)
        assert logged_in?

        get user_tournament_path(@user, @tournament)
        assert_response :success
    end

    test "Try to show a tournament for a different user" do
        log_in_as(@user)
        assert logged_in?

        get user_tournament_path(@other_user, @other_tournament)
        assert_response :forbidden
    end

    test "Try to show a tournament without logging in" do
        get user_tournament_path(@user, @tournament)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Try to show a non-existant tournament" do
        get user_tournament_path(@user, Tournament.ids.max + 1)
        assert_response :not_found
    end

    test "Get the tournament settings page" do
        log_in_as(@user)
        assert logged_in?

        get edit_user_tournament_path(@user, @tournament)
        assert_response :success
    end

    test "Try to get the tournament settings page for a different user" do
        log_in_as(@user)
        assert logged_in?

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
        assert logged_in?

        patch user_tournament_path(@user, @tournament),
              params: update_tournament_params(@tournament)

        assert_redirected_to user_tournament_path(@user, @tournament)
    end

    test "Try to update a tournament with invalid params" do
        log_in_as(@user)
        assert logged_in?

        params = update_tournament_params(@tournament)
        params[:tournament][:send_slack_notifications] = true
        params[:tournament][:slack_notifications_channel] = ""

        patch user_tournament_path(@user, @tournament), params: params

        assert_response :success
        assert_template "tournaments/edit"
    end

    test "Try to update a tournament for a different user" do
        log_in_as(@user)
        assert logged_in?

        patch user_tournament_path(@other_user, @other_tournament),
              params: update_tournament_params(@other_tournament)

        assert_response :forbidden
    end

    test "Try to update a tournament without logging in" do
        patch user_tournament_path(@user, @tournament),
              params: update_tournament_params(@tournament)

        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Try to finalize a tournament without logging in" do
        post finalize_user_tournament_path(@user, @tournament)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Try to finalize a tournament before it's allowed" do
        log_in_as(@user)
        assert logged_in?

        post finalize_user_tournament_path(@user, @tournament)
        assert_response :bad_request
    end
end
