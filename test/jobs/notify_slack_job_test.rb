require "test_helper"

class NotifySlackJobTest < ActiveJob::TestCase
    test "Send a Slack notification" do
        if (channel = ENV["CHALLONGE_MGR_TEST_SLACK_CHANNEL"])
            msg = "This is a test message from Challonge Mgr (user=#{ENV['USER']})"
            NotifySlackJob.perform_now(msg, channel)
        end
    end
end
