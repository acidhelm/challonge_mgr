class TournamentsController < ApplicationController
    before_action :set_user, only: [ :index, :refresh_all ]
    before_action :set_tournament, except: [ :index, :refresh_all, :view,
                                             :gold, :blue, :gold_score, :blue_score ]
    before_action :set_tournament_from_alphanumeric_id,
                  only: [ :gold, :blue, :gold_score, :blue_score ]
    before_action :require_login, except: [ :view, :gold, :blue, :gold_score, :blue_score ]
    before_action :correct_user?, except: [ :view, :gold, :blue, :gold_score, :blue_score ]

    # GET /tournaments
    def index
        @tournaments = @user.tournaments.underway.order(started_at: :desc)
    end

    # GET /tournaments/refresh
    def refresh_all
        tournaments_array = ApplicationHelper.get_tournament_list(@user)

        @tournaments = tournaments_array.map do |t|
            OpenStruct.new(t["tournament"])
        end.select do |t|
            Tournament.states_to_show.include? t.state
        end.map do |tournament_obj|
            tournament_record = @user.tournaments.find_or_initialize_by(
                                    challonge_id: tournament_obj.id)

            tournament_record.update!(tournament_obj)

            tournament_record
        end

        # Delete completed tournaments from the database.
        @user.tournaments.complete.each(&:destroy)

        redirect_to action: "index"
    end

    # GET /tournaments/1
    def show
    end

    # GET /tournaments/1/refresh
    def refresh
        # Re-read the info, matches, and teams for this tournament.
        tournament_hash = ApplicationHelper.get_tournament_info(@tournament)
        tournament_obj = OpenStruct.new(tournament_hash["tournament"])

        # Read the properties that we care about from the top level of the JSON,
        # and update the Tournament object.
        @tournament.update!(tournament_obj)

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        tournament_obj.participants.map do |participant|
            OpenStruct.new(participant["participant"])
        end.each do |participant_obj|
            team_record = @tournament.teams.find_or_initialize_by(
                              challonge_id: participant_obj.id)

            team_record.update!(participant_obj)
        end

        # Read the "matches" array and create a Match object for each one, or
        # update the Match if it's already in the database.
        tournament_obj.matches.map do |match|
            OpenStruct.new(match["match"])
        end.each do |match_obj|
            match_record = @tournament.matches.find_or_initialize_by(
                               challonge_id: match_obj.id)

            match_record.update!(match_obj)
        end

        redirect_to action: "show"
    end

    def edit
    end

    def update
        respond_to do |format|
            if @tournament.update(tournament_params)
                format.html { redirect_to user_tournament_path(@user, @tournament),
                                          notice: "The tournament was updated." }
            else
                format.html { render :edit }
            end
        end
    end

    def view
        @tournament = Tournament.readonly.find_by_challonge_alphanumeric_id(params[:id])

        if @tournament.present?
            @user = @tournament.user
            render :show, layout: "tournament_view"
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
    def set_user
        begin
            @user = User.find(params[:user_id])
        rescue ActiveRecord::RecordNotFound
            render_not_found_error(:user)
        end
    end

    def set_tournament
        begin
            @tournament = Tournament.find(params[:id])
            @user = @tournament.user
        rescue ActiveRecord::RecordNotFound
            render_not_found_error(:tournament)
        end
    end

    def set_tournament_from_alphanumeric_id
        @tournament = Tournament.find_by_challonge_alphanumeric_id(params[:id])
        render_not_found_error(:tournament) if @tournament.blank?
    end

    def current_match_team_name(side)
        name = ""

        begin
            if @tournament.current_match.present?
                name = Match.find(@tournament.current_match).team_name(side)
            end
        rescue ActiveRecord::RecordNotFound
        end

        return name
    end

    def current_match_team_score(side)
        score = 0

        begin
            if @tournament.current_match.present?
                score = Match.find(@tournament.current_match).team_score(side)
            end
        rescue ActiveRecord::RecordNotFound
        end

        return score
    end

    def tournament_params
        params.require(:tournament).
          permit(:gold_on_left, :send_slack_notifications, :slack_notifications_channel)
    end
end
