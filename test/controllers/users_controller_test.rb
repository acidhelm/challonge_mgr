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

end
