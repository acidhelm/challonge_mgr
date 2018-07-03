# frozen_string_literal: true

class NotifySlackJob < ApplicationJob
    queue_as :default

    SLACK_URL = "https://kqchat.slack.com/services/hooks/slackbot?token=#{ENV['SLACK_TOKEN']}"

    def perform(msg, channel_name, content_type = "text/plain")
        if ENV["SLACK_TOKEN"] && msg.present? && channel_name.present?
            url = "#{SLACK_URL}&channel=#{channel_name}"
            RestClient.post(url, msg, content_type: content_type)
        end
    end
end
