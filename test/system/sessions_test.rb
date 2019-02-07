require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
    test "Check the login page" do
        visit login_url

        assert_selector "label", exact_text: "User name:"
        assert_field "user_name"
        assert_selector "label", exact_text: "Password:"
        assert_field "password"

        assert_button "Log in", exact: true
    end
end
