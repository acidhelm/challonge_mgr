class TournamentsController < ApplicationController
    before_action :set_tournament, only: [:show, :start_match, :update_score,
                                          :update_winner]

    # GET /tournaments
    def index
        if params[:user].blank?
            redirect_to users_path, notice: "You must pass a \"user\" parameter in the URL."
            return
        end

        begin
            user = User.find(params[:user])
        rescue ActiveRecord::RecordNotFound
            redirect_to users_path, notice: "That user was not found."
            return
        end

        if params[:refresh].blank?
            @tournaments = user.tournaments.where(state: "underway")
            return
        end

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments.json"
        response = RestClient.get(url)
        tournaments_array = JSON.parse(response.body)

        @tournaments = tournaments_array.map do |t|
            OpenStruct.new(t["tournament"])
        end.select do |t|
            t.state == "underway"
        end.map do |tournament_obj|
            tournament_record = user.tournaments.find_or_initialize_by(
                                    challonge_id: tournament_obj.id)

            tournament_record.description = tournament_obj.description
            tournament_record.name = tournament_obj.name
            tournament_record.challonge_alphanumeric_id = tournament_obj.url
            tournament_record.state = tournament_obj.state
            tournament_record.challonge_url = tournament_obj.full_challonge_url
            tournament_record.tournament_type = tournament_obj.tournament_type
            tournament_record.gold_on_left ||= Rails.configuration.gold_on_left_default

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
        # then create a new Tournament object, or update the Tournament if it's
        # already in the database.
        tournament_record = user.tournaments.find_or_initialize_by(
                                challonge_id: tournament_obj.id)

        tournament_record.description = tournament_obj.description
        tournament_record.name = tournament_obj.name
        tournament_record.state = tournament_obj.state
        tournament_record.challonge_url = tournament_obj.full_challonge_url
        tournament_record.tournament_type = tournament_obj.tournament_type

        tournament_record.save

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        tournament_obj.participants.map do |participant|
            OpenStruct.new(participant["participant"])
        end.each do |participant_obj|
            team_record = @tournament.teams.find_or_initialize_by(
                              challonge_id: participant_obj.id)

            team_record.name = participant_obj.name
            team_record.seed = participant_obj.seed

            team_record.save
        end

        # Read the "matches" array and create a Match object for each one, or
        # update the Match if it's already in the database.
        tournament_obj.matches.map do |match|
            OpenStruct.new(match["match"])
        end.each do |match_obj|
            match_record = @tournament.matches.find_or_initialize_by(
                               challonge_id: match_obj.id)

            match_record.state = match_obj.state
            match_record.team1_id = match_obj.player1_id
            match_record.team2_id = match_obj.player2_id
            match_record.winner_id = match_obj.winner_id
            match_record.round = match_obj.round
            match_record.suggested_play_order = match_obj.suggested_play_order
            match_record.scores_csv = match_obj.scores_csv
            match_record.underway_at = match_obj.underway_at
            match_record.team1_prereq_match_id = match_obj.player1_prereq_match_id
            match_record.team2_prereq_match_id = match_obj.player2_prereq_match_id
            match_record.team1_is_prereq_match_loser = match_obj.player1_is_prereq_match_loser
            match_record.team2_is_prereq_match_loser = match_obj.player2_is_prereq_match_loser

            # If this match's teams are not TBD, and the teams have not been
            # assigned cabs yet (which means that this match just switched from
            # TBD to not-TBD), then set the teams' colors.  Team 1 defaults to
            # the left cab, and team 2 defaults to the right cab.
            if !match_record.teams_are_tbd? && match_record.gold_team_id.nil?
                if match_record.tournament.gold_on_left
                    match_record.gold_team_id = match_record.team1_id
                    match_record.blue_team_id = match_record.team2_id
                else
                    match_record.gold_team_id = match_record.team2_id
                    match_record.blue_team_id = match_record.team1_id
                end
            end

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
        team1_score = params[:team1_score]
        team2_score = params[:team2_score]
        new_scores_csv = "#{team1_score}-#{team2_score}"

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
