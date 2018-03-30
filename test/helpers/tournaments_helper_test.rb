require "test_helper"

class TournamentsHelperTest < ActionView::TestCase
    setup do
        @tournament = tournaments(:one)
    end

    test "Test the match-starting Slack message" do
        match = @tournament.matches.where(state: "open").order(challonge_id: :asc).first
        msg = TournamentsHelper.get_match_starting_msg(@tournament, match, nil)

        assert_equal "Elbonia KQ Clash: Match #3 is about to start:" \
                       " Northwise Meeps vs. CGNU Dumples.", msg
    end

    test "Test the match-complete Slack message" do
        match = @tournament.matches.where(state: "complete").order(challonge_id: :desc).first
        msg = TournamentsHelper.get_match_complete_msg(@tournament, match)

        assert_equal "Elbonia KQ Clash: Northwise Meeps defeated Pile of" \
                       " Electronics State 3-1.", msg
    end
end
