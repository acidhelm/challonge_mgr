require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "Get the login page" do
        get login_path
        assert_response :success
    end
end
