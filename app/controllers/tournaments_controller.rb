class TournamentsController < ApplicationController
    before_action :set_user
    before_action :set_tournament, except: [ :index, :refresh_all ]

    # GET /tournaments
    def index
        @tournaments = @user.tournaments.underway?
    end

    # GET /tournaments/refresh
    def refresh_all
        url = "https://#{@user.user_name}:#{@user.api_key}@api.challonge.com/" \
                "v1/tournaments.json"
        response = RestClient.get(url)
        tournaments_array = JSON.parse(response.body)

        @tournaments = tournaments_array.map do |t|
            OpenStruct.new(t["tournament"])
        end.select do |t|
            Tournament.states_to_show.include? t.state
        end.map do |tournament_obj|
            tournament_record = @user.tournaments.find_or_initialize_by(
                                    challonge_id: tournament_obj.id)

            tournament_record.update!(tournament_obj)
            tournament_record.save

            tournament_record
        end

        redirect_to user_tournaments_path(@user)
    end

    # GET /tournaments/1
    def show
    end

    # GET /tournaments/1/refresh
    def refresh
        # Re-read the info, matches, and teams for this tournament.
        url = "https://#{@user.user_name}:#{@user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{@tournament.challonge_id}.json?" \
                "include_participants=1&include_matches=1"
        response = RestClient.get(url)
        tournament_hash = JSON.parse(response.body)
        tournament_obj = OpenStruct.new(tournament_hash["tournament"])

        # Read the properties that we care about from the top level of the JSON,
        # and update the Tournament object.
        @tournament.update!(tournament_obj)
        @tournament.save

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

        redirect_to user_tournament_path(@user, @tournament)
    end

    def edit
    end

    def update
        respond_to do |format|
            if @tournament.update(tournament_params)
                format.html { redirect_to user_tournament_path(@user, @tournament) }
            else
                format.html { render :edit }
            end
        end
    end

    protected
    def set_user
        @user = nil

        begin
            @user = User.find(params[:user_id])
        rescue ActiveRecord::RecordNotFound
            render plain: "That user was not found.", status: :not_found
        end

        return @user.present?
    end

    def set_tournament
        @tournament = nil

        begin
            @tournament = Tournament.find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render plain: "That tournament was not found.", status: :not_found
        end

        return @tournament.present?
    end

    def tournament_params
        params.require(:tournament).
          permit(:gold_on_left, :send_slack_notifications, :slack_notifications_channel)
    end
end
