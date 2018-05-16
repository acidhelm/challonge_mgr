require "application_system_test_case"

class TournamentsTest < ApplicationSystemTestCase
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
end
