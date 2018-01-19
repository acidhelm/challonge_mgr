module TournamentsHelper
    SLACK_URL = "https://kqchat.slack.com/services/hooks/slackbot?token=wKN1vmWfX2J8ONngB8vdq3YD"

    def self.notify_match_starting(tournament, match, next_match = nil)
        msg = "#{tournament.name}: Match ##{match.number} is about to start:" \
                " #{match.left_team_name} vs. #{match.right_team_name}." \

        if next_match
            msg << " The on-deck match is #{next_match.left_team_name || "TBD"} vs." \
                     " #{next_match.right_team_name || "TBD"}."
        end

        # notify_slack(tournament.slack_channel, msg)
    end

    def self.notify_match_complete(tournament, match)
        msg = "#{tournament.name}: #{match.winning_team_name} defeated" \
                " #{match.losing_team_name}" \
                " #{match.winning_team_score}-#{match.losing_team_score}."

        # notify_slack(tournament.slack_channel, msg)
    end

    def self.notify_slack(slack_channel, msg)
        url = "#{SLACK_URL}&channel=#{slack_channel}"

        RestClient.post(url, msg, content_type: "text/plain")
    end
end
