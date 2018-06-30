# frozen_string_literal: true

class TournamentsController < ApplicationController
    before_action :set_user, only: %i(index refresh_all)
    before_action :set_tournament, except: %i(index refresh_all)
    before_action :require_login
    before_action :correct_user?

    def index
        @tournaments = @user.tournaments.underway.order(started_at: :desc)
    end

    def refresh_all
        # Make a list of the tournaments that are currently in the database.
        # We will delete any tournaments whose state has changed to complete.
        known_tournaments = @user.tournaments.pluck(:challonge_id)

        # Get the user's tournaments from Challonge.
        tournament_list = ApplicationHelper.get_tournament_list(@user)

        return if api_failed?(tournament_list) do |msg|
            redirect_to({ action: "index" }, notice: msg)
        end

        # - Make a struct for each tournament in the response.
        # - Find the tournaments that are not complete, or are already in
        #   the database.
        # - Create or update those tournaments with the properties that were
        #   in the response.
        tournament_list.each do |t|
            s = OpenStruct.new(t["tournament"])

            if Tournament.states_to_show.include?(s.state) ||
               known_tournaments.include?(s.id)
                @user.tournaments.find_or_initialize_by(challonge_id: s.id).update!(s)
            end
        end

        # Delete completed tournaments from the database.
        @user.tournaments.complete.destroy_all

        redirect_to action: "index"
    end

    def show
    end

    def refresh
        # Re-read the info, matches, and teams for this tournament.
        tournament_hash = ApplicationHelper.get_tournament_info(@tournament)

        return if api_failed?(tournament_hash) do |msg|
            redirect_to({ action: "show" }, notice: msg)
        end

        tournament_obj = OpenStruct.new(tournament_hash["tournament"])

        # Update the tournament with the properties that were in the response.
        @tournament.update!(tournament_obj)

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        # If a tournament is restarted on Challonge and a team is deleted, we
        # we need to reflect that change in the database.  Keep track of the
        # `challonge_id` of the Teams that are currently in the database, and
        # delete the rows for teams that have been deleted from the tournament
        # on Challonge.
        old_team_ids = @tournament.teams.pluck(:challonge_id)

        tournament_obj.participants.each do |p|
            s = OpenStruct.new(p["participant"])

            @tournament.teams.find_or_initialize_by(challonge_id: s.id).update!(s)
            old_team_ids.delete s.id
        end

        # If `old_team_ids` is non-empty, then those matches were deleted from
        # the Challonge tournament, so delete them from our database, too.
        if old_team_ids.present?
            @tournament.teams.where(challonge_id: old_team_ids).destroy_all
        end

        # Read the "matches" array and create a Match object for each one, or
        # update the Match if it's already in the database.
        # If a tournament is restarted on Challonge, the old matches are deleted
        # and new ones are made, so we need to reflect that change in the database.
        # Keep track of the `challonge_id` of the Matches that are currently in
        # the database, and delete the rows for Matches that have been deleted
        # from the Challonge tournament.
        old_match_ids = @tournament.matches.pluck(:challonge_id)

        tournament_obj.matches.each do |m|
            s = OpenStruct.new(m["match"])

            @tournament.matches.find_or_initialize_by(challonge_id: s.id).update!(s)
            old_match_ids.delete s.id
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
            # If the user creates a tournament and clicks the "Edit settings"
            # link in the tournaments/index view, before they ever click the
            # "Manage this tournament" link, then we need to redirect to the
            # refresh action so the teams and matches are filled in.
            # Otherwise, redirect to the show action.
            action = @tournament.matches.blank? ? "refresh" : "show"
            msg = I18n.t("notices.tournament_updated")

            redirect_to({ action: action }, notice: msg)
        else
            render :edit
        end
    end

    def finalize
        # Bail out if the tournament can't be finalized now.
        if !@tournament.finalizable?
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
