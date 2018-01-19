class MatchesController < ApplicationController
    before_action :set_match

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

        url = "https://#{@user.user_name}:#{@user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{@tournament.challonge_id}/matches/" \
                "#{@match.challonge_id}.json"

        response = RestClient.put(url, post_data,
                                  content_type: "application/x-www-form-urlencoded")
        match_obj = OpenStruct.new(JSON.parse(response.body)["match"])

        @match.update!(match_obj)
        @match.save

        # If `winner_id` is present, then the current match is over.
        @tournament.set_match_complete(@match) if winner_id.present?

        redirect_to refresh_user_tournament_path(@user, @tournament)
    end

    def switch
        @match.switch_team_sides!
        @match.save

        redirect_to user_tournament_path(@user, @tournament)
    end

    protected
    def set_match
        @match = nil

        begin
            @match = Match.find(params[:id])
            @tournament = @match.tournament
            @user = @tournament.user
        rescue ActiveRecord::RecordNotFound
            render plain: "That match was not found.", status: :not_found
        end

        return @match.present?
    end
end
