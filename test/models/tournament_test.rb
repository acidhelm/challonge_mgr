require "test_helper"

class TournamentTest < ActiveSupport::TestCase
    def setup
        @tournament = tournaments(:one)
    end

    test "Try to save a tournament with an illegal challonge_id" do
        @tournament.challonge_id = -1
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal name" do
        @tournament.name = ""
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal challonge_alphanumeric_id" do
        @tournament.challonge_alphanumeric_id = ""
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal state" do
        @tournament.state = ""
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal challonge_url" do
        @tournament.challonge_url = ""
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal tournament_type" do
        @tournament.tournament_type = ""
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal view_gold_score" do
        @tournament.view_gold_score = -1
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal view_blue_score" do
        @tournament.view_blue_score = -1
        assert_not @tournament.save
    end

    test "Try to save a tournament with a blank slack_notifications_channel" do
        @tournament.send_slack_notifications = true
        @tournament.slack_notifications_channel = ""
        assert_not @tournament.save
    end

    test "Save a tournament with a slack_notifications_channel" do
        @tournament.send_slack_notifications = true
        @tournament.slack_notifications_channel = "buzz"
        assert @tournament.save
    end
end
