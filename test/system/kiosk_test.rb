require "application_system_test_case"

class KioskTest < ApplicationSystemTestCase
    test "Check the kiosk page" do
        tournament = tournaments(:tournament_2)

        visit tournament_kiosk_url(tournament.challonge_alphanumeric_id)

        assert_selector "h1", exact_text: tournament.name

        assert_selector "tbody tr:first-child td:first-child", exact_text: "Current match:"
        assert_selector "tbody tr:first-child td:nth-child(2)", text: "UC Sunnydale Wildcats"
        assert_selector "tbody tr:first-child td:nth-child(2)", text: "The Scoobies"

        assert_selector "tbody tr:nth-child(2) td:first-child", exact_text: "On deck:"
        assert_selector "tbody tr:nth-child(2) td:nth-child(2)", text: "Sunnyvale Slayers"
        assert_selector "tbody tr:nth-child(2) td:nth-child(2)", text: "TBD"

        assert_selector "tbody tr:nth-child(3) td:first-child", exact_text: "After that:"
    end
end
