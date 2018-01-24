module TournamentsHelper
    SLACK_URL = "https://kqchat.slack.com/services/hooks/slackbot?token=#{ENV['SLACK_TOKEN']}"

    def self.notify_match_starting(tournament, match, next_match = nil)
        msg = "#{tournament.name}: Match ##{match.number} is about to start:" \
                " #{match.team_name(:left)} vs. #{match.team_name(:right)}." \

        if next_match
            msg << " The on-deck match is #{next_match.team_name(:left) || "TBD"} vs." \
                     " #{next_match.team_name(:right) || "TBD"}."
        end

        notify_slack(tournament.slack_notifications_channel, msg)
    end

    def self.notify_match_complete(tournament, match)
        msg = "#{tournament.name}: #{match.team_name(:winner)} defeated" \
                " #{match.team_name(:loser)}" \
                " #{match.winning_team_score}-#{match.losing_team_score}."

        notify_slack(tournament.slack_notifications_channel, msg)
    end

    def self.notify_slack(slack_channel, msg)
        url = "#{SLACK_URL}&channel=#{slack_channel}"

        RestClient.post(url, msg, content_type: "text/plain")
    end
end
