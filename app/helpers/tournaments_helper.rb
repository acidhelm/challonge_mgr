module TournamentsHelper
    def self.notify_match_starting(tournament, match, next_match = nil)
        msg = "#{tournament.name}: Match ##{match.number} is about to start:" \
                " #{match.team_name(:left)} vs. #{match.team_name(:right)}." \

        if next_match
            left_team_name = next_match.team_name(:left)
            right_team_name = next_match.team_name(:right)

            # If both team names are `nil`, then don't show the on-deck match
            # message.  This happens for the first match of the finals in a
            # double-elimination tournament.
            if left_team_name || right_team_name
                # If one team is TBD, always show that one second.
                first_team_name = left_team_name || right_team_name
                second_team_name = left_team_name.nil? ? nil : right_team_name
                second_team_name ||= "TBD"

                msg << " The on-deck match is #{first_team_name} vs. #{second_team_name}."
            end
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
