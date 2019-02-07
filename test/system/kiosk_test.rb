require "application_system_test_case"

class KioskTest < ApplicationSystemTestCase
    test "Check the kiosk page" do
        tournament = tournaments(:tournament_2)

        visit tournament_kiosk_url(tournament.challonge_alphanumeric_id)

        assert_selector "h1", exact_text: tournament.name

        within "table tbody" do
            within "tr:first-child" do
                assert_selector "td:first-child", exact_text: "Current match:"

                within "td:nth-child(2)" do
                    assert_text "UC Sunnydale Wildcats"
                    assert_text "The Scoobies"
                end
            end

            within "tr:nth-child(2)" do
                assert_selector "td:first-child", exact_text: "On deck:"

                within "td:nth-child(2)" do
                    assert_text "Sunnyvale Slayers"
                    assert_text "TBD"
                end
            end

            assert_selector "tr:nth-child(3) td:first-child", exact_text: "After that:"
        end
    end

    test "Check for meta refresh tags" do
        tag = "/html/head/meta[@http-equiv='refresh']"

        visit tournament_kiosk_url(tournaments(:tournament_1).challonge_alphanumeric_id)

        assert page.find(:xpath, tag, visible: false)

        visit tournament_kiosk_url(tournaments(:live_data_tournament).challonge_alphanumeric_id)

        assert_raises(Capybara::ElementNotFound) do
            page.find(:xpath, tag, visible: false)
        end
    end
end
