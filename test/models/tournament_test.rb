require "test_helper"

class TournamentTest < ActiveSupport::TestCase
    def setup
        @tournament = tournaments(:one)
    end

    test "Mark a match as complete" do
        @tournament = tournaments(:two)
        @match = @tournament.current_match_obj

        assert_not_nil @match

        # Manually set the Slack notification properties here.  I could do this
        # in the fixture, but then other tests might also send Slack messages,
        # and I want to minimize the number of messages that we send.
        channel_name = ENV["CHALLONGE_MGR_TEST_SLACK_CHANNEL"]

        @tournament.slack_notifications_channel = channel_name
        @tournament.send_slack_notifications = channel_name.present?

        # Manually set properties on `@match` to make it complete.  Doing this
        # the official way, using `MatchesController`, would try to update a
        # non-existant tournament on Challonge.
        @match.state = "complete"
        @match.scores_csv = "2-3"
        @match.winner_id = @match.team2_id
        @match.loser_id = @match.team1_id

        @tournament.set_match_complete(@match)

        assert_nil @tournament.current_match_obj
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

    test "Try to save a tournament with a duplicate challonge_alphanumeric_id" do
        t2 = @tournament.dup
        t2.challonge_alphanumeric_id.upcase!

        # Make these fields different, so we only test the validation of
        # `challonge_alphanumeric_id`.
        t2.challonge_id += 1
        t2.challonge_url += "giles"

        assert_not t2.save
    end

    test "Try to save a tournament with an illegal state" do
        @tournament.state = ""
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal challonge_url" do
        @tournament.challonge_url = ""
        assert_not @tournament.save
    end

    test "Try to save a tournament with a duplicate challonge_url" do
        t2 = @tournament.dup
        t2.challonge_url.upcase!

        # Make these fields different, so we only test the validation of
        # `challonge_url`.
        t2.challonge_id += 1
        t2.challonge_alphanumeric_id += "wesley"

        assert_not t2.save
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

    test "Try to save a tournament with an illegal started_at" do
        @tournament.started_at = 37.minutes.from_now
        assert_not @tournament.save
    end

    test "Try to save a tournament with an illegal subdomain" do
        @tournament.subdomain = "domain~!"
        assert_not @tournament.save
    end
end
