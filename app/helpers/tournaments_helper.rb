module TournamentsHelper
    def self.notify_match_starting(tournament, match, next_match = nil)
        msg = "#{tournament.name}: Match ##{match.number} is about to start:" \
                " #{match.team_name(:left)} vs. #{match.team_name(:right)}." \

        if next_match
            msg << " The on-deck match is #{next_match.team_name(:left) || "TBD"} vs." \
                     " #{next_match.team_name(:right) || "TBD"}."
        end

        notify_slack(msg, tournament.slack_notifications_channel)
    end

    def self.notify_match_complete(tournament, match)
        msg = "#{tournament.name}: #{match.team_name(:winner)} defeated" \
                " #{match.team_name(:loser)}" \
                " #{match.team_score(:winner)}-#{match.team_score(:loser)}."

        notify_slack(msg, tournament.slack_notifications_channel)
    end

    def self.notify_slack(msg, channel_name)
        NotifySlackJob.perform_later(msg, channel_name)
    end
end
