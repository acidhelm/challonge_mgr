require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "Get the login page" do
        get login_path
        assert_response :success
    end

    test "Access the logout URL" do
        delete logout_path
        assert_redirected_to root_url
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
