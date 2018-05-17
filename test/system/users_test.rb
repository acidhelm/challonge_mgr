require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
    test "Check the tournament list" do
        assert_selector "h1", text: /^Challonge tournaments owned by/
        assert_selector "a", text: "Reload the tournament list from Challonge"
        assert_selector "a", text: "Edit this user's settings"
        assert_selector "a", text: "Log out"

        page.all("th").each do |th|
            assert th.text.present?
        end

        page.all("tbody tr").each do |tr|
            tr.all("td").each_with_index do |td, i|
                case i
                    when 0, 1
                        assert td.text.present?
                    when 2
                        assert URI.parse(td.text)
                    when 3
                        td.assert_selector "a", text: "Manage this tournament"
                        td.assert_selector "a", text: "Edit this tournament's settings"
                end
            end
        end
    end

    test "Check the user settings page" do
        new_password = "B055man!69"

        visit edit_user_url(@user)

        fill_in "user_api_key", with: "buffythevampireslayer"
        fill_in "user[subdomain]", with: "drusilla"
        fill_in "user[password]", with: new_password
        fill_in "user[password_confirmation]", with: new_password

        click_on "Update User"

        assert_current_path(user_path(@user))
    end

    test "Check the user properties page" do
        visit user_url(@user)

        assert_text "User name:"
        assert_text @user.user_name
        assert_text "API key:"
        assert_text @user.api_key
        assert_text "Subdomain:"
        assert_text @user.subdomain if @user.subdomain.present?

        assert_selector "a", text: "Edit this user's settings"
        assert_selector "a", text: "View this user's tournaments"
        assert_selector "a", text: "Log out"
    end
end
