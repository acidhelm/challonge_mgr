require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
    setup do
        @tournament = tournaments(:tournament_1)
        @user = @tournament.user
        @other_tournament = tournaments(:tournament_2)
        @other_user = @other_tournament.user
        @test_user = users(:user_test)
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

    test "Refresh the list of tournaments" do
        log_in_as(@test_user)
        assert logged_in?

        VCR.use_cassette("refresh_tournament_list") do
            get user_tournaments_refresh_path(@test_user)
        end

        assert_redirected_to user_tournaments_path(@test_user)
    end

    test "Refresh the list of tournaments, simulating that tournaments have been removed" do
        log_in_as(@user)
        assert logged_in?

        # Our simulated response is an empty list, so all of the user's
        # tournaments should be deleted from the database.
        stub_request(:get, get_api_url).
            with(query: hash_including(api_key: @user.api_key)).
            to_return(body: [].to_json)

        assert_changes(-> { @user.tournaments.count },
                       from: @user.tournaments.count, to: 0) do
            get user_tournaments_refresh_path(@user)
        end

        assert_redirected_to user_tournaments_path(@user)
    end

    test "Automatically manage a tournament" do
        log_in_as(@test_user)
        assert logged_in?

        # Refresh the test user's tournament list so we can operate on a tournament.
        VCR.use_cassette("refresh_tournament_list") do
            get user_tournaments_refresh_path(@test_user)
        end

        @tournament = @test_user.tournaments.first

        # If the user has no tournaments, we can't run this test, but we don't
        # treat that as a test failure.
        if @tournament.blank?
            puts "Warning: [#{method_name}] The test user has no tournaments." \
                   " This test is not running any assertions."

            return
        end

        # Refresh the tournament list again and pass the `autostart` param.
        VCR.use_cassette("refresh_tournament_list") do
            get user_tournaments_refresh_path(
                  @test_user, autostart: @tournament.challonge_alphanumeric_id)
        end

        # The controller should redirect to the tournament/refresh action, as if
        # the user clicked the Manage link, and then redirect again to the
        # tournament/show action.
        assert_redirected_to refresh_user_tournament_path(@test_user, @tournament)
        follow_redirect!
        assert_redirected_to user_tournament_path(@test_user, @tournament)
    end

    test "Try to refresh the list of tournaments with an invalid API key" do
        log_in_as(@test_user)
        assert logged_in?

        @test_user.update(api_key: @test_user.api_key.succ)

        VCR.use_cassette("refresh_tournament_list_fail") do
            get user_tournaments_refresh_path(@test_user)
        end

        assert_redirected_to user_tournaments_path(@test_user)
        assert_not flash.empty?
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

        assert assigns(:teams_in_seed_order)
        assert_not assigns(:teams_in_final_rank_order)
    end

    test "Show a completed tournament" do
        @tournament = tournaments(:tournament_3)

        log_in_as(@user)
        assert logged_in?

        get user_tournament_path(@user, @tournament)
        assert_response :success

        assert assigns(:teams_in_seed_order)
        assert assigns(:teams_in_final_rank_order)
    end

    test "Refresh a tournament" do
        # Add the live tournament to the user's `tournaments` collection so the
        # controller can redirect to its "show" action.
        @tournament = tournaments(:live_data_tournament)
        @test_user.tournaments << @tournament

        log_in_as(@test_user)
        assert logged_in?

        VCR.use_cassette("refresh_tournament") do
            get refresh_user_tournament_path(@test_user, @tournament)
        end

        assert_redirected_to user_tournament_path(@test_user, @tournament)
    end

    test "Try to refresh a tournament with an invalid API key" do
        # Add the live tournament to the user's `tournaments` collection so the
        # controller can redirect to its "show" action.
        @tournament = tournaments(:live_data_tournament)
        @test_user.tournaments << @tournament

        log_in_as(@test_user)
        assert logged_in?

        @test_user.update(api_key: @test_user.api_key.succ)

        VCR.use_cassette("refresh_tournament_fail") do
            get refresh_user_tournament_path(@test_user, @tournament)
        end

        assert_redirected_to user_tournament_path(@test_user, @tournament)
        assert_not flash.empty?
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

    test "Set teams' alt names" do
        log_in_as(@user)
        assert logged_in?

        params = update_tournament_params(@tournament)

        params[:team_alt_names] = @tournament.teams.map(&:name)
        params[:team_ids] = @tournament.teams.map(&:id)

        patch user_tournament_path(@user, @tournament), params: params

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

    test "Try to update teams' alt names with invalid params" do
        log_in_as(@user)
        assert logged_in?

        params = update_tournament_params(@tournament)
        names = @tournament.teams.map(&:name)
        ids = @tournament.teams.ids

        # Test with arrays of different sizes.
        params[:team_alt_names] = names
        params[:team_ids] = ids
        params[:team_ids] << 42

        patch user_tournament_path(@user, @tournament), params: params

        assert_response :bad_request

        # Test with duplicate IDs.
        params[:team_ids] = ids
        params[:team_ids][1] = params[:team_ids][0]

        patch user_tournament_path(@user, @tournament), params: params

        assert_response :bad_request

        # Test with an invalid ID.
        params[:team_ids] = ids
        params[:team_ids][0] = params[:team_ids].max + 1

        patch user_tournament_path(@user, @tournament), params: params

        assert_response :bad_request
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

    test "Finalize a tournament" do
        @tournament = tournaments(:tournament_4)

        # The API returns the tournament's updated attributes, but the
        # controller doesn't read the response, so we can just return the
        # existing attributes.
        resp = { tournament: @tournament.attributes }.to_json

        log_in_as(@user)
        assert logged_in?

        stub_request(:post, get_api_url("#{@tournament.challonge_id}/finalize.json")).
            to_return(body: resp)

        post finalize_user_tournament_path(@user, @tournament)
        assert_redirected_to refresh_user_tournament_path(@user, @tournament)
    end

    test "Try to finalize a tournament, with an API failure" do
        @tournament = tournaments(:tournament_4)

        log_in_as(@user)
        assert logged_in?

        stub_request(:post, get_api_url("#{@tournament.challonge_id}/finalize.json")).
            to_return(make_api_error_response(status: 404, message: "File not found"))

        post finalize_user_tournament_path(@user, @tournament)
        assert_redirected_to user_tournament_path(@user, @tournament)
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
