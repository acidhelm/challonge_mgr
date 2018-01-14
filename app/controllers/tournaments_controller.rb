class TournamentsController < ApplicationController
    before_action :set_tournament, except: [ :index ]

    # GET /tournaments
    def index
        if params[:user].blank?
            redirect_to users_path, notice: "You must pass a \"user\" parameter in the URL."
            return
        end

        begin
            @user_id = params[:user]
            user = User.find(@user_id)
            @user_name = user.user_name
        rescue ActiveRecord::RecordNotFound
            redirect_to users_path, notice: "That user was not found."
            return
        end

        if params[:refresh].blank?
            @tournaments = user.tournaments.underway?
            return
        end

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments.json"
        response = RestClient.get(url)
        tournaments_array = JSON.parse(response.body)

        @tournaments = tournaments_array.map do |t|
            OpenStruct.new(t["tournament"])
        end.select do |t|
            Tournament.states_to_show.include? t.state
        end.map do |tournament_obj|
            tournament_record = user.tournaments.find_or_initialize_by(
                                    challonge_id: tournament_obj.id)

            tournament_record.update!(tournament_obj)
            tournament_record.save

            tournament_record
        end
    end

    # GET /tournaments/1
    def show
        return unless @tournament.present?

        return if params[:refresh].blank?

        # Re-read the info, matches, and teams for this tournament.
        user = @tournament.user
        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{@tournament.challonge_id}.json?" \
                "include_participants=1&include_matches=1"
        response = RestClient.get(url)
        tournament_hash = JSON.parse(response.body)
        tournament_obj = OpenStruct.new(tournament_hash["tournament"])

        # Read the properties that we care about from the top level of the JSON,
        # and update the Tournament object.
        tournament_record = user.tournaments.find_by(
                                challonge_id: tournament_obj.id)

        tournament_record.update!(tournament_obj)
        tournament_record.save

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        tournament_obj.participants.map do |participant|
            OpenStruct.new(participant["participant"])
        end.each do |participant_obj|
            team_record = @tournament.teams.find_or_initialize_by(
                              challonge_id: participant_obj.id)

            team_record.update!(participant_obj)
            team_record.save
        end

        # Read the "matches" array and create a Match object for each one, or
        # update the Match if it's already in the database.
        tournament_obj.matches.map do |match|
            OpenStruct.new(match["match"])
        end.each do |match_obj|
            match_record = @tournament.matches.find_or_initialize_by(
                               challonge_id: match_obj.id)

            match_record.update!(match_obj)
            match_record.save
        end
    end

    def start_match
        return unless @tournament.present?

        @tournament.update(current_match: params[:match_id])
        redirect_to @tournament
    end

    def update_score
        return unless @tournament.present?

        user = @tournament.user
        match_id = params[:match_id]
        match = @tournament.matches.find_by_challonge_id(match_id)
        left_score = params[:left_score]
        right_score = params[:right_score]
        new_scores_csv = match.make_scores_csv(left_score, right_score)

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{@tournament.challonge_id}/matches/#{match_id}.json"

        response = RestClient.put(url, "match[scores_csv]=#{new_scores_csv}",
                                  content_type: "application/x-www-form-urlencoded")
        match_obj = OpenStruct.new(JSON.parse(response.body)["match"])

        match.state = match_obj.state
        match.scores_csv = match_obj.scores_csv
        match.save

        redirect_to @tournament
    end

    def update_winner
        return unless @tournament.present?

        user = @tournament.user
        match_id = params[:match_id]
        match = @tournament.matches.find_by_challonge_id(match_id)
        winner_id = params[:winner_id]

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{@tournament.challonge_id}/matches/#{match_id}.json"

        response = RestClient.put(url,
                                  "match[scores_csv]=#{match.scores_csv}&" \
                                    "match[winner_id]=#{winner_id}",
                                  content_type: "application/x-www-form-urlencoded")

        match_obj = OpenStruct.new(JSON.parse(response.body)["match"])

        match.state = match_obj.state
        match.scores_csv = match_obj.scores_csv
        match.save

        @tournament.update(current_match: nil)

        redirect_to tournament_path(@tournament, refresh: 1)
    end

    def switch_sides
        return unless @tournament.present?

        match_id = params[:match_id]
        match = @tournament.matches.find_by_challonge_id(match_id)

        match.switch_team_sides!
        match.save

        redirect_to @tournament
    end

    def switch_cabinet_sides
        return unless @tournament.present?

        @tournament.toggle!(:gold_on_left)

        redirect_to @tournament
    end

    protected
    def set_tournament
        @tournament = nil
        id = params[:id]

        # If the ID is all numbers, look for a Tournament whose primary key is
        # that number.
        if id =~ /^\d+$/
            begin
                @tournament = Tournament.find(id)
            rescue ActiveRecord::RecordNotFound
                # Eat the exception; we'll try searching again, treating `id` as
                # the `challonge_alphanumeric_id`.
            end
        end

        if @tournament.nil?
            @tournament = Tournament.find_by_challonge_alphanumeric_id(id)
        end

        if @tournament.nil?
            render plain: "That tournament was not found.", status: :not_found
        end

        return @tournament.present?
    end
end
