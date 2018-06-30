require "test_helper"

class MatchTest < ActiveSupport::TestCase
    def setup
        @match = matches(:one)
    end

    test "Update a match" do
        @match.scores_csv = "4-2"
        @match.winner_id = @match.team1_id
        @match.loser_id = @match.team2_id
        assert @match.save
    end

    test "Try to save a match with an duplicate challonge_id" do
        m2 = @match.dup
        assert_not m2.save
    end

    test "Try to save a match with an illegal challonge_id" do
        @match.challonge_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an illegal state" do
        @match.state = ""
        assert_not @match.save
    end

    test "Try to save a match with an illegal round" do
        @match.round = 37.42
        assert_not @match.save
    end

    test "Try to save a match with an illegal suggested_play_order" do
        @match.suggested_play_order = 37.42
        assert_not @match.save
    end

    test "Try to save a match with an illegal identifier" do
        @match.identifier = ""
        assert_not @match.save
    end

    test "Try to save a match with an invalid scores_csv" do
        @match.scores_csv = "homeschool-winner"
        assert_not @match.save
    end

    test "Try to save a match with an illegal team1_id" do
        @match.team1_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an illegal team2_id" do
        @match.team2_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an illegal winner_id" do
        @match.winner_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an illegal loser_id" do
        @match.loser_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an illegal team1_prereq_match_id" do
        @match.team1_prereq_match_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an illegal team2_prereq_match_id" do
        @match.team2_prereq_match_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an illegal group_id" do
        @match.group_id = -1
        assert_not @match.save
    end

    test "Try to save a match with an invalid winner_id and loser_id" do
        # Set winner_id and loser_id to nil in a completed match.
        @match.winner_id = nil
        assert_not @match.save

        @match.winner_id, @match.loser_id = @match.loser_id, @match.winner_id
        assert_not @match.save

        # Set winner_id and loser_id to non-nil in an uncompleted match.
        @match = matches(:three)

        @match.winner_id = @match.team1_id
        assert_not @match.save

        @match.winner_id, @match.loser_id = @match.loser_id, @match.winner_id
        assert_not @match.save
    end

    test "Try to save a match where winner_id and loser_id are not in the match" do
        @match.winner_id *= 2
        assert_not @match.save

        @match.winner_id, @match.loser_id = @match.loser_id, @match.winner_id
        assert_not @match.save
    end
end
