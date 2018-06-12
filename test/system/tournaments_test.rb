require "application_system_test_case"

class TournamentsTest < ApplicationSystemTestCase
    setup :setup_log_in

    test "Check the tournament settings page" do
        begin
            # If the user has no tournaments, this call will throw an exception,
            # but we don't treat that as a test failure.
            row_elt = page.find("tbody tr:first-child")
        rescue Capybara::ElementNotFound
            puts "Warning: The test user has no tournaments. This test is not" \
                   " running any assertions."
        end

        if row_elt
            edit_settings_link = row_elt.find("a:nth-child(2)")
            tournament_url = edit_settings_link["href"]
            assert_equal "/edit", tournament_url.slice!(%r{/[^/]+$})

            edit_settings_link.click

            assert_selector "h1", text: /^Edit settings for/
            assert_selector "label", text: "The Gold cabinet is on the left side"
            assert_field id: "tournament_gold_on_left", type: "checkbox"
            assert_selector "label", text: "Send Slack notifications when matches begin and end"
            assert_field id: "tournament_send_slack_notifications", type: "checkbox"
            assert_selector "label", text: "Slack channel"
            assert_field name: "tournament[slack_notifications_channel]", type: "text"

            page.find_by_id("tournament_gold_on_left").click
            page.find_by_id("tournament_send_slack_notifications").click
            fill_in "tournament[slack_notifications_channel]", with: "ucsunnydale"

            click_on "Update Tournament"

            assert_current_path(tournament_url)
        end
    end

    test "Check the show-tournament page" do
        begin
            # If the user has no tournaments, this call will throw an exception,
            # but we don't treat that as a test failure.
            row_elt = page.find("tbody tr:first-child")
        rescue Capybara::ElementNotFound
            puts "Warning: The test user has no tournaments. This test is not" \
                   " running any assertions."
        end

        if row_elt
            manage_link = row_elt.find("td:nth-child(4) a:nth-child(1)")
            manage_url = manage_link["href"]
            tournament_id = manage_url.match(%r{/tournaments/(\d+)})[1]
            tournament = @user.tournaments.find(tournament_id)

            VCR.use_cassette("get_tournament_info") do
                manage_link.click

                # This call has to be within the use_cassette block, because
                # `click` returns right away.  `assert_selector` spins, looking
                # for the element, and the HTTP request happens during that loop.
                assert_selector "h1", text: tournament.name
            end

            assert_link tournament.challonge_url, href: tournament.challonge_url

            # Since this is using live data from Challonge, we can't predict
            # what the Upcoming Matches, Completed Matches, and Team Records
            # sections will contain.  The Team Records section will always exist,
            # so we can look for that.
            assert_selector "h2", text: "Team records:"
            assert_selector "th", text: "Seed"
            assert_selector "th", text: "Team (W-L)"

            assert_link "Reload this tournament from Challonge",
                        href: refresh_user_tournament_path(@user, tournament)

            assert_link "Edit this tournament's settings",
                        href: edit_user_tournament_path(@user, tournament)

            assert_link "Back to the tournament list",
                        href: user_tournaments_path(@user)

            assert_link "Log Out", href: logout_path
        end
    end
end
