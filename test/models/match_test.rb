require "test_helper"

class MatchTest < ActiveSupport::TestCase
    def setup
        @match = matches(:one)
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
end
