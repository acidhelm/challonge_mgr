require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "Get the login page" do
        get login_path
        assert_response :success
    end

    test "Log in" do
        log_in_as(users(:willow))
    end

    test "Access the logout URL" do
        delete logout_path
        assert_redirected_to root_url
    end

    test "Try to log in with incorrect credentials" do
        user = users(:willow)

        post login_path, params: { session: { user_name: user.user_name,
                                              password: "invalidpassword" } }

        assert_not logged_in?
        assert_not flash.empty?
        assert_template "sessions/new"
    end

    test "Try to get a user page without logging in" do
        get user_path(users(:willow).id)
        assert_redirected_to login_path
        assert flash.present?
    end

    test "Try to get the routes page" do
        assert_raises(ActionController::RoutingError) { get "/routes" }
    end
end
