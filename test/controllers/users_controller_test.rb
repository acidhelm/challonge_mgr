require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
        @user = users(:user_willow)
        @other_user = users(:user_buffy)
    end

    def update_user_params
        return { user: { api_key: @user.api_key, subdomain: @user.subdomain,
                         password: "B055man69", password_confirmation: "B055man69" } }
    end

    # Uses WebMock to simulate a successful Challonge API call for some of the
    # steps of creating a demo tournament.
    def stub_demo_tournament_call(alphanumeric_id, *args)
        args.each do |arg|
            case arg
                when :create
                    # Since `ChallongeHelper#make_demo_tournament` only reads the
                    # `url` member of the response (which corresponds to
                    # `Tournament#challonge_alphanumeric_id`), we can use a simple response.
                    url = get_api_url
                    resp = { tournament: { url: alphanumeric_id } }

                when :add
                    # `ChallongeHelper#make_demo_tournament` doesn't use any of the
                    # data in the response, so we can use a simple response.
                    url = get_api_url("#{alphanumeric_id}/participants/bulk_add.json")
                    resp = [ { participant: {} } ]

                when :start
                    # Make the call to start the tournament succeed.
                    # `UsersController#demo` only reads the `url` member of the
                    # response, so we can use a simple response.
                    url = get_api_url("#{alphanumeric_id}/start.json")
                    resp = { tournament: { url: alphanumeric_id } }
            end

            stub_request(:post, url).to_return(body: resp.to_json)
        end
    end

    test "Show a user" do
        log_in_as(@user)
        assert logged_in?

        get user_url(@user)
        assert_response :success
    end

    test "Try to show a different user" do
        log_in_as(@user)
        assert logged_in?

        get user_url(@other_user)
        assert_response :forbidden
    end

    test "Try to show a user without logging in" do
        get user_url(@user)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Try to show a non-existant user" do
        get user_url(User.ids.max + 1)
        assert_response :not_found
    end

    test "Get the edit user page" do
        log_in_as(@user)
        assert logged_in?

        get edit_user_url(@user)
        assert_response :success
    end

    test "Try to get the edit user page for a different user" do
        log_in_as(@user)
        assert logged_in?

        get edit_user_url(@other_user)
        assert_response :forbidden
    end

    test "Try to get the edit user page without logging in" do
        get edit_user_url(@user)
        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Update a user" do
        log_in_as(@user)
        assert logged_in?

        patch user_url(@user), params: update_user_params

        assert_redirected_to user_url(@user)
    end

    test "Try to update a different user" do
        log_in_as(@user)
        assert logged_in?

        patch user_url(@other_user), params: update_user_params
        assert_response :forbidden
    end

    test "Try to update a user without logging in" do
        patch user_url(@user), params: update_user_params

        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Try to update a user with invalid params" do
        log_in_as(@user)
        assert logged_in?

        params = update_user_params
        params[:user][:api_key] = ""

        patch user_url(@user), params: params

        assert_response :success
        assert_template "users/edit"
    end

    test "Update a user's show_quick_start property" do
        log_in_as(@user)
        assert logged_in?
        assert @user.show_quick_start

        post user_hidedemo_path(@user)
        @user.reload
        assert_not @user.show_quick_start
    end

    test "Try to update the show_quick_start property for a different user" do
        log_in_as(@user)
        assert logged_in?

        post user_hidedemo_path(@other_user)
        assert_response :forbidden
    end

    test "Try to update a user's show_quick_start property without logging in" do
        post user_hidedemo_path(@user)

        assert_redirected_to login_url
        assert_not flash.empty?
    end

    test "Create a demo tournament" do
        log_in_as(@user)
        assert logged_in?

        alphanumeric_id = "testdemotournament"

        stub_demo_tournament_call(alphanumeric_id, :create, :add, :start)

        post user_demo_path(@user)
        assert_redirected_to refresh_user_tournaments_path(@user, autostart: alphanumeric_id)
        assert flash.empty?
    end

    test "Try to create a demo tournament, with an API failure when creating the tournament" do
        log_in_as(@user)
        assert logged_in?

        stub_request(:post, get_api_url).to_return(make_api_error_response)

        post user_demo_path(@user)
        assert_redirected_to user_tournaments_path(@user)
        assert_not flash.empty?
    end

    test "Try to create a demo tournament, with an API failure when creating teams" do
        log_in_as(@user)
        assert logged_in?

        alphanumeric_id = "testdemotournament"

        stub_demo_tournament_call(alphanumeric_id, :create)

        # Make the call to add teams fail.
        stub_request(:post, get_api_url("#{alphanumeric_id}/participants/bulk_add.json")).
            to_return(make_api_error_response)

        post user_demo_path(@user)
        assert_redirected_to user_tournaments_path(@user)
        assert_not flash.empty?
    end

    test "Try to create a demo tournament, with an API failure when starting the tournament" do
        log_in_as(@user)
        assert logged_in?

        alphanumeric_id = "testdemotournament"

        stub_demo_tournament_call(alphanumeric_id, :create, :add)

        # Make the call to start the tournament fail.
        stub_request(:post, get_api_url("#{alphanumeric_id}/start.json")).
            to_return(make_api_error_response)

        post user_demo_path(@user)
        assert_redirected_to user_tournaments_path(@user)
        assert_not flash.empty?
    end
end
