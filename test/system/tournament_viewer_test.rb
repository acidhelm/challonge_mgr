require "application_system_test_case"

class TournamentViewerTest < ApplicationSystemTestCase
    test "Check the view-tournament page" do
        tournament = tournaments(:one)

        visit "/view/#{tournament.challonge_alphanumeric_id}"

        assert_selector "h1", text: tournament.name
        assert_link tournament.challonge_url, href: tournament.challonge_url

        # We're using a made-up tournament from the fixture, so we know that
        # all three of these sections will be present.
        assert_selector "h2", text: "Upcoming matches:"
        assert_selector "th", text: "Match #"
        assert_selector "th", text: "Round"
        assert_selector "th", text: "Teams"

        assert_selector "h2", text: "Completed matches:"
        assert_selector "th", text: "Match #"
        assert_selector "th", text: "Round"
        assert_selector "th", text: "Teams"

        assert_selector "h2", text: "Team records:"
        assert_selector "th", text: "Seed"
        assert_selector "th", text: "Team (W-L)"
    end
end
