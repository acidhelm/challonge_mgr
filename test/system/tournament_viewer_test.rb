require "application_system_test_case"

class TournamentViewerTest < ApplicationSystemTestCase
    test "Check the view-tournament page" do
        tournament = tournaments(:one)

        visit view_tournament_url(tournament.challonge_alphanumeric_id)

        assert_selector "h1", exact_text: tournament.name
        assert_link tournament.challonge_url, href: tournament.challonge_url,
                    exact: true

        # We're using a made-up tournament from the fixture, so we know that
        # all three of these sections will be present.
        assert_selector "h2", exact_text: "Upcoming matches:"
        assert_selector "th", exact_text: "Match #"
        assert_selector "th", exact_text: "Round"
        assert_selector "th", exact_text: "Teams"

        assert_selector "h2", exact_text: "Completed matches:"
        assert_selector "th", exact_text: "Match #"
        assert_selector "th", exact_text: "Round"
        assert_selector "th", exact_text: "Teams"

        assert_selector "h2", exact_text: "Team records:"
        assert_selector "th", exact_text: "Seed"
        assert_selector "th", exact_text: "Team (W-L)"
    end
end
