# frozen_string_literal: true

module TournamentsHelper
    # Sends a message to Slack that announces the start of a match, and
    # optionally, the teams in the next match.
    def self.notify_match_starting(tournament, match, next_match = nil)
        msg = get_match_starting_msg(tournament, match, next_match)
        notify_slack(msg, tournament.slack_notifications_channel)
    end

    # Sends a message to Slack that announces the end of a match.
    def self.notify_match_complete(tournament, match)
        msg = get_match_complete_msg(tournament, match)
        notify_slack(msg, tournament.slack_notifications_channel)
    end

    # Builds the string that announces the start of a match.
    def self.get_match_starting_msg(tournament, match, next_match)
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

        return msg
    end

    # Builds the string that announces the end of a match.
    def self.get_match_complete_msg(tournament, match)
        return I18n.t("slack.match_complete", tournament_name: tournament.name,
                      winning_team: match.team_name(:winner),
                      losing_team: match.team_name(:loser),
                      winning_score: match.team_score(:winner),
                      losing_score: match.team_score(:loser))
    end

    # Sends a message to a Slack channel asynchronously.
    def self.notify_slack(msg, channel_name)
        NotifySlackJob.perform_later(msg, channel_name)
    end
end
