class TournamentViewerController < ApplicationController
    before_action :set_tournament

    def view
        if @tournament.present?
            @user = @tournament.user
            render "tournaments/show", layout: "tournament_view"
        else
            render_not_found_error(:tournament)
        end
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
    def set_tournament
        @tournament = Tournament.readonly.where("lower(challonge_alphanumeric_id) = ?",
                                                params[:id].downcase).first

        render_not_found_error(:tournament) if @tournament.blank?
    end

    def current_match_team_name(side)
        name = nil

        begin
            if @tournament.current_match.present?
                name = Match.find(@tournament.current_match).team_name(side)
            else
                name = (side == :gold) ? @tournament.view_gold_name :
                                         @tournament.view_blue_name
            end
        rescue ActiveRecord::RecordNotFound
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
            if @tournament.current_match.present?
                score = Match.find(@tournament.current_match).team_score(side)
            else
                score = (side == :gold) ? @tournament.view_gold_score :
                                          @tournament.view_blue_score
            end
        rescue ActiveRecord::RecordNotFound
        end

        return score
    end
end
