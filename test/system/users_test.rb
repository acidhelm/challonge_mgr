require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
    setup do
        @user = users(:test_user)
        log_in_as(@user)
    end

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
end
