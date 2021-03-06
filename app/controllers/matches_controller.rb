# frozen_string_literal: true

class MatchesController < ApplicationController
    before_action :set_match
    before_action :require_login
    before_action :correct_user?

    def start
        # Tell the tournament that a new match is starting.
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
        # If the winner is not being set, check that the caller passed scores
        # for both sides.
        if winner_id.present?
            # We consider it an error if the caller passed scores and a `winner_id`.
            if left_score.present? || right_score.present?
                head :bad_request
                return
            end
        elsif left_score.blank? || right_score.blank?
            head :bad_request
            return
        end

        # Send the new scores or the winner to Challonge.
        match_hash = @match.update_scores(left_score, right_score, winner_id)

        return if api_failed?(match_hash) do |msg|
            redirect_to user_tournament_path(@user, @tournament), notice: msg
        end

        # Challonge responds with the updated JSON for the match.  Read it and
        # update our `Match` object.
        match_obj = OpenStruct.new(match_hash["match"])

        @match.update!(match_obj)

        # If `winner_id` is present, then the current match is over.
        @tournament.set_match_complete(@match) if winner_id.present?

        # If we are finishing a match, then we need to refresh the tournament,
        # because the result of this match may change the teams that are
        # in future matches.  If we're just updating the score of the current
        # match, there's no need to refresh the tournament.
        if winner_id.present?
            redirect_to refresh_user_tournament_path(@user, @tournament, get_teams: 0)
        else
            redirect_to user_tournament_path(@user, @tournament)
        end
    end

    def switch
        @match.switch_team_sides!
        redirect_to user_tournament_path(@user, @tournament)
    end

    private

    def set_match
        @user = User.find(params[:user_id])
        @tournament = @user.tournaments.find(params[:tournament_id])
        @match = @tournament.matches.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render_not_found_error(:match)
    end
end
