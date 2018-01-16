class MatchesController < ApplicationController
    before_action :set_match

    def start
        @match.tournament.update(current_match: @match.id)
        redirect_to user_tournament_path(@match.tournament.user, @match.tournament)
    end

    def update
        tournament = @match.tournament
        user = tournament.user
        left_score = params[:left_score]
        right_score = params[:right_score]
        winner_id = params[:winner_id]

        if winner_id.present?
            new_scores_csv = @match.scores_csv
        else
            new_scores_csv = @match.make_scores_csv(left_score, right_score)
        end

        post_data = "match[scores_csv]=#{new_scores_csv}"
        post_data << "&match[winner_id]=#{winner_id}" if winner_id.present?

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{tournament.challonge_id}/matches/" \
                "#{@match.challonge_id}.json"

        response = RestClient.put(url, post_data,
                                  content_type: "application/x-www-form-urlencoded")
        match_obj = OpenStruct.new(JSON.parse(response.body)["match"])

        @match.state = match_obj.state
        @match.scores_csv = match_obj.scores_csv
        @match.save

        tournament.update(current_match: nil) if winner_id.present?

        redirect_to refresh_user_tournament_path(user, tournament)
    end

    def switch
        @match.switch_team_sides!
        @match.save

        redirect_to user_tournament_path(@match.tournament.user, @match.tournament)
    end

    protected
    def set_match
        @match = nil

        begin
            @match = Match.find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render plain: "That match was not found.", status: :not_found
        end

        return @match.present?
    end
end
