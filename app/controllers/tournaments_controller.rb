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
            tournament_record = user.tournaments.find_by(challonge_id: t.id)

            if tournament_record.present?
                tournament_record.update(description: t.description,
                                         name: t.name,
                                         state: t.state,
                                         challonge_url: t.full_challonge_url)

                tournament_record
            else
                user.tournaments.create!(
                  description: t.description, challonge_id: t.id, name: t.name,
                  state: t.state, challonge_url: t.full_challonge_url)
            end
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
        tournament_record = Tournament.find_by(challonge_id: tournament_obj.id)

        if tournament_record.present?
            tournament_record.update(description: tournament_obj.description,
                                     name: tournament_obj.name,
                                     state: tournament_obj.state,
                                     challonge_url: tournament_obj.full_challonge_url)
        else
            user.tournaments.create!(
              description: tournament_obj.description, challonge_id: tournament_obj.id,
              name: tournament_obj.name, state: tournament_obj.state,
              challonge_url: tournament_obj.full_challonge_url)
        end

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        tournament_obj.participants.map do |participant|
            OpenStruct.new(participant["participant"])
        end.each do |participant_obj|
            team_record = Team.find_by(challonge_id: participant_obj.id)

            if team_record.present?
                team_record.update(name: participant_obj.name, seed: participant_obj.seed)
            else
                @tournament.teams.create!(name: participant_obj.name,
                                          seed: participant_obj.seed,
                                          challonge_id: participant_obj.id)
            end
        end
    end
end
