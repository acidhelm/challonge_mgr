require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
    setup :setup_log_in

    test "Check the tournament list" do
        assert_selector "h1", text: /^Challonge tournaments owned by/

        # The footer should have three links.
        assert_link "Reload the tournament list from Challonge",
                    href: user_tournaments_refresh_path(@user), exact: true
        assert_link "Change this user's settings", href: edit_user_path(@user), exact: true
        assert_link "Log out", href: logout_path, exact: true

        # Check the column headers in the tournament table.
        header_text = %w(Name State Actions Links)

        page.all("th").each_with_index do |th, i|
            assert th.text == header_text[i]
        end

        # Check the list of tournaments.
        page.all("tbody tr").each do |tr|
            tr.all("td").each_with_index do |td, i|
                case i
                    when 0, 1
                        # The Name and State columns should have text.
                        assert td.text.present?
                    when 2
                        # The Actions column should have two links.
                        assert td.has_link? "Manage this tournament", exact: true
                        assert td.has_link? "Change settings", exact: true
                    when 3
                        # The Links column should have three links.
                        assert td.has_link? "Challonge", exact: true
                        assert td.has_link? "Spectator view", exact: true
                        assert td.has_link? "Kiosk", exact: true

                        # Check that the "Challonge" link points to a valid
                        # Challonge URL.
                        uri = URI.parse(td.find("a:nth-child(1)")[:href])

                        assert uri.host =~ /^([^.]+\.)?challonge\.com$/
                        assert uri.path =~ /^\/\w+$/
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
