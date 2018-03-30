# frozen_string_literal: true

class MatchesController < ApplicationController
    before_action :set_match
    before_action :require_login
    before_action :correct_user?

    def start
        @tournament.set_current_match(@match)
        redirect_to user_tournament_path(@user, @tournament)
    end

    def update
        left_score = params[:left_score]
        right_score = params[:right_score]
        winner_id = params[:winner_id]

        # If `winner_id` is present, then the caller is setting the winner, not
        # changing the score.  Challonge requires us to send the `scores_csv`
        # param, even if we're just setting the winner, so use the match's
        # current scores.
        if winner_id.present?
            new_scores_csv = @match.scores_csv
        else
            new_scores_csv = @match.make_scores_csv(left_score, right_score)
        end

        post_data = "match[scores_csv]=#{new_scores_csv}"
        post_data << "&match[winner_id]=#{winner_id}" if winner_id.present?

        match_hash = ApplicationHelper.update_match(@match, post_data)
        match_obj = OpenStruct.new(match_hash["match"])

        @match.update!(match_obj)

        # If `winner_id` is present, then the current match is over.
        @tournament.set_match_complete(@match) if winner_id.present?

        # If we are finishing a match, then we need to refresh the tournament,
        # because the result of this match may have changed the teams that are
        # in future matches.  If we're just updating the score of the current
        # match, there's no need to refresh the tournament.
        if winner_id.present?
            redirect_to refresh_user_tournament_path(@user, @tournament)
        else
            redirect_to user_tournament_path(@user, @tournament)
        end
    end

    def switch
        @match.switch_team_sides!
        redirect_to user_tournament_path(@user, @tournament)
    end

    protected
    def set_match
        begin
            @match = Match.find(params[:id])
            @tournament = @match.tournament
            @user = @tournament.user
        rescue ActiveRecord::RecordNotFound
            render_not_found_error(:match)
        end
    end
end
