require "test_helper"

class NotifySlackJobTest < ActiveJob::TestCase
    test "Send a Slack notification" do
        if ENV["CHALLONGE_MGR_TEST_SLACK_CHANNEL"]
            NotifySlackJob.perform_now("This is a test message from Challonge Mgr (user=#{ENV['USER']})",
                                       ENV["CHALLONGE_MGR_TEST_SLACK_CHANNEL"])
        end
    end
end
