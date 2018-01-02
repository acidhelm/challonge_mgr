class TournamentsController < ApplicationController
    # GET /tournaments
    def index
        if params[:user].blank?
            redirect_to "/users", notice: "You must pass a \"user\" parameter in the URL."
            return
        end

        begin
            user = User.find(params[:user])
        rescue ActiveRecord::RecordNotFound
            redirect_to "/users", notice: "That user was not found."
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
        end.map do |t|
            tournament_record = user.tournaments.find_or_create_by!(challonge_id: t.id)

            tournament_record.description = t.description
            tournament_record.name = t.name
            tournament_record.state = t.state
            tournament_record.challonge_url = t.full_challonge_url

            tournament_record.save
            tournament_record
        end
    end

    # GET /tournaments/1
    def show
        @tournament = Tournament.find(params[:id])

        return if params[:refresh].blank?

        # Re-read the info, matches, and teams for this tournament.
        user = @tournament.user
        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{@tournament.challonge_id}.json?"\
                "include_participants=1&include_matches=1"
        response = RestClient.get(url)
        tournament_hash = JSON.parse(response.body)
        tournament_obj = OpenStruct.new(tournament_hash["tournament"])

        # Read the properties that we care about from the top level of the JSON,
        # then create a new Tournament object, or update the Tournament if it's
        # already in the database.
        tournament_record = user.tournaments.find_or_create_by!(
                                challonge_id: tournament_obj.id)

        tournament_record.description = tournament_obj.description
        tournament_record.name = tournament_obj.name
        tournament_record.state = tournament_obj.state
        tournament_record.challonge_url = tournament_obj.full_challonge_url

        tournament_record.save

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        tournament_obj.participants.map do |participant|
            OpenStruct.new(participant["participant"])
        end.each do |participant_obj|
            team_record = @tournament.teams.find_or_create_by!(
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
            match_record = @tournament.matches.find_or_create_by!(
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

            match_record.save
        end
    end
end
