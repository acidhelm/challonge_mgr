require "application_system_test_case"

class TournamentsTest < ApplicationSystemTestCase
    setup :setup_log_in

    test "Check the tournament list" do
        visit user_tournaments_path(@user)

        assert_selector "h1", exact_text: "Challonge tournaments owned by #{@user.user_name}"

        # Bail out if the test user has no tournaments.
        if !has_selector? "table#tournament_list"
            puts "Warning: [#{method_name}] The test user has no tournaments." \
                   " This test is not running any assertions."

            return
        end

        # Check the column headers in the tournament table.
        within "table#tournament_list thead" do
            %w(Name State Actions Links).each do |text|
                assert_selector "th", exact_text: text
            end
        end

        # Check the list of tournaments.
        page.all("table#tournament_list tbody tr").each do |tr|
            tournament = Tournament.find(tr[:id].slice(/\d+\z/))

            tr.all("td").each_with_index do |td, i|
                case i
                    when 0
                        if tournament.subdomain.present?
                            assert_equal "#{tournament.name} [#{tournament.subdomain}]",
                                         td.text
                        else
                            assert_equal tournament.name, td.text
                        end
                    when 1
                        if tournament.state == "underway"
                            assert_equal "underway (#{tournament.progress_meter}% done)", td.text
                        else
                            assert_equal ActiveSupport::Inflector.humanize(tournament.state, capitalize: false),
                                         td.text
                        end
                    when 2
                        assert td.has_link? "Manage this tournament", exact: true,
                                            href: refresh_user_tournament_path(@user, tournament)

                        assert td.has_link? "Change settings", exact: true,
                                            href: edit_user_tournament_path(@user, tournament)
                    when 3
                        slug = tournament.challonge_alphanumeric_id

                        assert td.has_link? "Challonge", exact: true,
                                            href: tournament.challonge_url

                        assert td.has_link? "Spectator view", exact: true,
                                            href: view_tournament_path(slug)

                        assert td.has_link? "Kiosk", exact: true,
                                            href: tournament_kiosk_path(slug)
                end
            end
        end

        # The footer should have three links.
        assert_link "Reload the tournament list from Challonge",
                    href: user_tournaments_refresh_path(@user), exact: true
        assert_link "Change this user's settings", href: edit_user_path(@user), exact: true
        assert_link "Log out", href: logout_path, exact: true
    end

    test "Hide the quick start section" do
        visit user_tournaments_path(@user)

        # Check that the quick start section is visible.
        within "#quick_start" do
            assert_selector "h3", exact_text: "Quick start demo"
            assert_button "Create a demo tournament", exact: true
            assert_button "Hide this section", exact: true
        end

        # Click the button that hides it.
        click_on "Hide this section"

        assert_no_selector "#quick_start"
    end

    test "Check the tournament settings page" do
        visit user_tournaments_path(@user)

        begin
            # If the user has no tournaments, this call will throw an exception,
            # but we don't treat that as a test failure.
            row_elt = page.find("tbody tr:first-child")
        rescue Capybara::ElementNotFound
            puts "Warning: [#{method_name}] The test user has no tournaments." \
                   " This test is not running any assertions."
        end

        return unless row_elt

        edit_settings_link = row_elt.find("td:nth-child(3) a:nth-child(2)")
        tournament = Tournament.find(row_elt[:id].slice(/\d+\z/))

        edit_settings_link.click

        assert_selector "h1", exact_text: "Change settings for #{tournament.name}"
        assert_selector "label", exact_text: "The Gold cabinet is on the left side"
        assert_field id: "tournament_gold_on_left", type: "checkbox"
        assert_selector "label", exact_text: "Send Slack notifications when " \
                                               "matches begin and end"
        assert_field id: "tournament_send_slack_notifications", type: "checkbox"
        assert_selector "label", exact_text: "Slack channel:"
        assert_field name: "tournament[slack_notifications_channel]", type: "text"
        assert_button "Update Tournament", exact: true
        assert_link "Cancel", exact: true

        page.find_by_id("tournament_gold_on_left").click
        page.find_by_id("tournament_send_slack_notifications").click
        fill_in "tournament[slack_notifications_channel]", with: "ucsunnydale"

        VCR.use_cassette("get_tournament_info") do
            click_on "Update Tournament"

            assert_current_path(user_tournament_path(@user, tournament))
        end
    end

    test "Check the show-tournament page" do
        visit user_tournaments_path(@user)

        begin
            # If the user has no tournaments, this call will throw an exception,
            # but we don't treat that as a test failure.
            row_elt = page.find("tbody tr:first-child")
        rescue Capybara::ElementNotFound
            puts "Warning: [#{method_name}] The test user has no tournaments." \
                   " This test is not running any assertions."
        end

        return unless row_elt

        manage_link = row_elt.find("td:nth-child(3) a:nth-child(1)")
        tournament = Tournament.find(row_elt[:id].slice(/\d+\z/))

        VCR.use_cassette("get_tournament_info") do
            manage_link.click

            # This call has to be within the `use_cassette` block, because
            # `click` returns right away.  `assert_selector` spins, looking
            # for the element, and the HTTP request happens during that loop.
            assert_selector "h1", exact_text: tournament.name
        end

        slug = tournament.challonge_alphanumeric_id

        assert_link "Challonge bracket", href: tournament.challonge_url, exact: true
        assert_link "Spectator view", href: view_tournament_path(slug), exact: true
        assert_link "Kiosk", href: tournament_kiosk_path(slug), exact: true

        # Since this is using live data from Challonge, we can't predict
        # what the Upcoming Matches, Completed Matches, and Team Records
        # sections will contain.  The Team Records section will always exist,
        # so we can look for that.
        assert_selector "h2", exact_text: "Team records:"
        assert_selector "th", exact_text: "Seed"
        assert_selector "th", exact_text: "Team (W-L)"

        assert_link "Reload this tournament from Challonge", exact: true,
                    href: refresh_user_tournament_path(@user, tournament)

        assert_link "Change settings", exact: true,
                    href: edit_user_tournament_path(@user, tournament)

        assert_link "Back to the tournament list", exact: true,
                    href: user_tournaments_path(@user)

        assert_link "Log Out", href: logout_path, exact: true
    end
end
