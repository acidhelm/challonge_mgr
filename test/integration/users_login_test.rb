require "test_helper"

class UsersLoginTest < ActionDispatch::IntegrationTest
    def setup
        @user = users(:user_willow)
    end

    test "Try to log in with invalid credentials" do
        get login_path
        assert_response :success
        assert_template "sessions/new"

        post login_path, params: { session: { user_name: "foo", password: "bar" } }
        assert_template "sessions/new"
        assert_not flash.empty?
        assert_not logged_in?

        get root_path
        assert_response :success
        assert flash.empty?
    end

    test "Log in with valid credentials, then log out" do
        get login_path
        assert_response :success
        assert_template "sessions/new"

        post login_path, params: { session: { user_name: @user.user_name,
                                              password: "password" } }

        # We don't follow this redirect, because it will contact Challonge,
        # and we're not using a real Challonge account in this test.
        assert_redirected_to user_tournaments_refresh_path(@user)
        assert logged_in?

        delete logout_path
        assert_not logged_in?
        assert_redirected_to root_url
    end
end
