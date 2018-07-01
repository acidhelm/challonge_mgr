class TournamentViewerController < ApplicationController
    before_action :set_tournament_from_slug

    def view
        @user = @tournament.user
        render "tournaments/show", layout: "tournament_view"
    end

    def gold
        render plain: current_match_team_name(:gold)
    end

    def blue
        render plain: current_match_team_name(:blue)
    end

    def gold_score
        render plain: current_match_team_score(:gold)
    end

    def blue_score
        render plain: current_match_team_score(:blue)
    end

    protected

    def current_match_team_name(side)
        name = nil

        begin
            # If a match is in progress, query the team name from that match.
            # Otherwise, use the team name that we stored when the match finished.
            if @tournament.current_match.present?
                name = Match.find(@tournament.current_match).team_name(side)
            else
                name = (side == :gold) ? @tournament.view_gold_name :
                                         @tournament.view_blue_name
            end
        rescue ActiveRecord::RecordNotFound
            # Do nothing, we'll return an empty string.
        end

        # Remove a parenthesized part from the end of the team name.  This lets
        # the Challonge bracket have names like "Bert's Bees (PHX)", but the
        # name on the stream will be just "Bert's Bees".  That saves space on the
        # stream, which is espcially necessary with multi-scene teams that have
        # multiple cities in the name.
        return name ? name.sub(/\(.*?\)$/, '').strip : ""
    end

    def current_match_team_score(side)
        score = 0

        begin
            # If a match is in progress, query the score from that match.
            # Otherwise, use the score that we stored when the match finished.
            if @tournament.current_match.present?
                score = Match.find(@tournament.current_match).team_score(side)
            else
                score = (side == :gold) ? @tournament.view_gold_score :
                                          @tournament.view_blue_score
            end
        rescue ActiveRecord::RecordNotFound
            # Do nothing, we'll return 0.
        end

        return score
    end
end
