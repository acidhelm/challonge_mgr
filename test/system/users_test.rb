require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
    setup :setup_log_in

    test "Check the redirect after logging in" do
        assert_current_path(user_tournaments_path(@user))
    end

    test "Check the user settings page" do
        new_password = "B055man!69"

        visit edit_user_url(@user)

        assert_selector "h1", exact_text: "Change settings for #{@user.user_name}"
        assert_selector "label", text: "Challonge API key:"
        assert_link "Find your API key", exact: true,
                    href: "https://challonge.com/settings/developer"
        assert_field id: "user_api_key", type: "text", with: @user.api_key
        assert_selector "label", text: "Subdomain:"
        assert_field id: "user_subdomain", type: "text", with: @user.subdomain
        assert_selector "label", text: "Password:"
        assert_field id: "user_password", type: "password"
        assert_selector "label", exact_text: "Confirm the new password:"
        assert_field id: "user_password_confirmation", type: "password"
        assert_button "Update User"
        assert_link "Cancel"

        fill_in "user_api_key", with: "buffythevampireslayer"
        fill_in "user[subdomain]", with: "drusilla"
        fill_in "user[password]", with: new_password
        fill_in "user[password_confirmation]", with: new_password

        click_on "Update User"

        assert_current_path(user_path(@user))
    end

    test "Check the user properties page" do
        visit user_url(@user)

        assert_selector "h1", exact_text: "Account settings for #{@user.user_name}"
        assert_selector "strong", exact_text: "API key:"
        assert_text @user.api_key
        assert_selector "strong", exact_text: "Subdomain:"
        assert_text @user.subdomain if @user.subdomain.present?

        assert_link "Change this user's settings", href: edit_user_path(@user), exact: true
        assert_link "View this user's tournaments", href: user_tournaments_path(@user), exact: true
        assert_link "Log out", href: logout_path, exact: true
    end
end
