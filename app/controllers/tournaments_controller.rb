# frozen_string_literal: true

class TournamentsController < ApplicationController
    before_action :set_user, only: %i(index refresh_all)
    before_action :set_tournament, except: %i(index refresh_all)
    before_action :require_login
    before_action :correct_user?

    # GET /tournaments
    def index
        @tournaments = @user.tournaments.underway.order(started_at: :desc)
    end

    # GET /tournaments/refresh
    def refresh_all
        known_tournaments = @user.tournaments.pluck(:challonge_id)
        tournament_list = ApplicationHelper.get_tournament_list(@user)

        return if api_failed?(tournament_list) do |msg|
            redirect_to({ action: "index" }, notice: msg)
        end

        tournament_list.map do |t|
            OpenStruct.new(t["tournament"])
        end.select do |t|
            Tournament.states_to_show.include?(t.state) ||
              known_tournaments.include?(t.id)
        end.each do |t|
            @user.tournaments.find_or_initialize_by(challonge_id: t.id).update!(t)
        end

        # Delete completed tournaments from the database.
        @user.tournaments.complete.destroy_all

        redirect_to action: "index"
    end

    # GET /tournaments/1
    def show
    end

    # GET /tournaments/1/refresh
    def refresh
        # Re-read the info, matches, and teams for this tournament.
        tournament_hash = ApplicationHelper.get_tournament_info(@tournament)

        return if api_failed?(tournament_hash) do |msg|
            redirect_to({ action: "show" }, notice: msg)
        end

        tournament_obj = OpenStruct.new(tournament_hash["tournament"])

        # Read the properties that we care about from the top level of the JSON,
        # and update the Tournament object.
        @tournament.update!(tournament_obj)

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        # If a tournament is restarted on Challonge and a team is deleted, we
        # we need to reflect that change in the database.  Keep track of the
        # `challonge_id` of the Teams that are currently in the database, and
        # delete the rows for teams that have been deleted from the tournament
        # on Challonge.
        old_team_ids = @tournament.teams.pluck(:challonge_id)

        tournament_obj.participants.map do |p|
            OpenStruct.new(p["participant"])
        end.each do |p|
            @tournament.teams.find_or_initialize_by(challonge_id: p.id).update!(p)
            old_team_ids.delete p.id
        end

        # If `old_team_ids` is non-empty, then those matches were deleted from
        # the tournament, so delete them from our database, too.
        if old_team_ids.present?
            @tournament.teams.where(challonge_id: old_team_ids).destroy_all
        end

        # Read the "matches" array and create a Match object for each one, or
        # update the Match if it's already in the database.
        # If a tournament is restarted on Challonge, the old matches are deleted
        # and new ones are made, so we need to reflect that change in the database.
        # Keep track of the `challonge_id` of the Matches that are currently in
        # the database, and delete the rows for Matches that have been deleted
        # from the tournament on Challonge.
        old_match_ids = @tournament.matches.pluck(:challonge_id)

        tournament_obj.matches.map do |m|
            OpenStruct.new(m["match"])
        end.each do |m|
            @tournament.matches.find_or_initialize_by(challonge_id: m.id).update!(m)
            old_match_ids.delete m.id
        end

        # If `old_match_ids` is non-empty, then those matches were deleted from
        # the tournament, so delete them from our database, too.
        if old_match_ids.present?
            @tournament.matches.where(challonge_id: old_match_ids).destroy_all
        end

        @tournament.update_group_names

        redirect_to action: "show"
    end

    def edit
    end

    def update
        if @tournament.update(tournament_params)
            redirect_to user_tournament_path(@user, @tournament),
                        notice: I18n.t("notices.tournament_updated")
        else
            render :edit
        end
    end

    # POST /tournaments/1/finalize
    def finalize
        # A tournament can be finalized only if its state is "awaiting_review".
        if @tournament.state != "awaiting_review"
            render plain: I18n.t("errors.cant_finalize_tournament"), status: :bad_request
            return
        end

        response = ApplicationHelper.finalize_tournament(@tournament)

        return if api_failed?(response) do |msg|
            redirect_to({ action: "show" }, notice: msg)
        end

        # Now that the tournament is finalized, Challonge will fill in the
        # `final_rank` fields of the teams.  Refresh the tournament so we
        # read those fields.
        redirect_to action: "refresh"
    end

    protected
    def set_user
        @user = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
        render_not_found_error(:user)
    end

    def set_tournament
        @user = User.find(params[:user_id])
        @tournament = @user.tournaments.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render_not_found_error(:tournament)
    end

    def tournament_params
        params.require(:tournament).
          permit(:gold_on_left, :send_slack_notifications, :slack_notifications_channel)
    end
end
