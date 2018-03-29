module TournamentsHelper
    def self.notify_match_starting(tournament, match, next_match = nil)
        msg = I18n.t("slack.match_starting", tournament_name: tournament.name,
                     match_number: match.number, left_team: match.team_name(:left),
                     right_team: match.team_name(:right))

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
                second_team_name ||= I18n.t("slack.tbd")

                msg << I18n.t("slack.on_deck_match", first_team: first_team_name,
                              second_team: second_team_name)
            end
        end

        notify_slack(msg, tournament.slack_notifications_channel)
    end

    def self.notify_match_complete(tournament, match)
        msg = I18n.t("slack.match_complete", tournament_name: tournament.name,
                     winning_team: match.team_name(:winner),
                     losing_team: match.team_name(:loser),
                     winning_score: match.team_score(:winner),
                     losing_score: match.team_score(:loser))

        notify_slack(msg, tournament.slack_notifications_channel)
    end

    def self.notify_slack(msg, channel_name)
        NotifySlackJob.perform_later(msg, channel_name)
    end
end
