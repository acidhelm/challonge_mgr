require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "Get the login page" do
        get login_path
        assert_response :success
    end

    test "Try to get the routes page" do
        assert_raises(ActionController::RoutingError) { get "/routes" }
    end
end
