# frozen_string_literal: true

class TournamentsController < ApplicationController
    before_action :set_user, only: %i(index refresh_all)
    before_action :set_tournament, except: %i(index refresh_all)
    before_action :require_login
    before_action :correct_user?

    def index
        # Our intention is to show the most-recently-started tournament first,
        # since the user will probably be looking for the tournament that
        # they just started on Challonge.  However, in the Brewcade account,
        # some really old tournaments have `started_at == nil` in the JSON
        # that Challonge sends, and Postgres sorts them to the beginning of
        # the results.
        # To work around that, do two queries.  The tournaments that have their
        # `started_at` set properly go first, then the ones where `started_at`
        # is `nil`.
        good_tournaments = @user.tournaments.underway.where.not(started_at: nil).
                             order(started_at: :desc)
        buggy_tournaments = @user.tournaments.underway.where(started_at: nil).
                              order(updated_at: :desc)

        # `+` returns an `Array`, but that's fine, because we don't do any
        # further operations on the results.
        @tournaments = good_tournaments + buggy_tournaments
    end

    def refresh_all
        # Make a list of the tournaments that are currently in the database.
        # We will delete any tournaments whose state has changed to complete.
        known_tournaments = @user.tournaments.pluck(:challonge_id)

        # Get the user's tournaments from Challonge.
        tournament_list = @user.get_tournaments

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

            if Tournament.show_state?(s.state) || known_tournaments.include?(s.id)
                @user.tournaments.find_or_initialize_by(challonge_id: s.id).update!(s)
                known_tournaments.delete(s.id)
            end
        end

        # Delete completed tournaments from the database.
        @user.tournaments.complete.destroy_all

        # If any tournaments are in the database, but were not returned by
        # get_tournaments, delete them from the database.  This happens if
        # tournaments are deleted from Challonge, or if the user's subdomain
        # changes; we need to delete the tournaments that belong to the previous
        # subdomain.
        if known_tournaments.present?
            @user.tournaments.where(challonge_id: known_tournaments).destroy_all
        end

        # If the user just created a quick start demo tournament, manage it immediately.
        if params[:autostart]
            demo = @user.tournaments.find_by(challonge_alphanumeric_id: params[:autostart])

            if demo
                redirect_to refresh_user_tournament_path(@user, demo)
                return
            end
        end

        redirect_to action: "index"
    end

    def show
        @current_match = @tournament.current_match_obj
        @upcoming_matches = @tournament.matches.upcoming
        @completed_matches = @tournament.matches.completed
        @teams_in_seed_order = @tournament.teams.order(seed: :asc)

        if @tournament.complete?
            @teams_in_final_rank_order = @tournament.teams.where.not(final_rank: nil).
                                         order(final_rank: :asc, seed: :asc)
        end
    end

    def refresh
        # Re-read the info for this tournament.  By default, we also get the
        # teams and matches, but the caller can prevent us from getting that
        # info by passing query string params.
        get_teams = (params[:get_teams] || "1").to_i > 0
        get_matches = (params[:get_matches] || "1").to_i > 0

        tournament_hash = @tournament.get_info(get_teams: get_teams,
                                               get_matches: get_matches)

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
        if tournament_obj.participants
            old_team_ids = @tournament.teams.pluck(:challonge_id)

            tournament_obj.participants.each do |p|
                s = OpenStruct.new(p["participant"])

                @tournament.teams.find_or_initialize_by(challonge_id: s.id).update!(s)
                old_team_ids.delete(s.id)
            end

            # If `old_team_ids` is non-empty, then those matches were deleted from
            # the Challonge tournament, so delete them from our database, too.
            if old_team_ids.present?
                @tournament.teams.where(challonge_id: old_team_ids).destroy_all
            end
        end

        # Read the "matches" array and create a Match object for each one, or
        # update the Match if it's already in the database.
        # If a tournament is restarted on Challonge, the old matches are deleted
        # and new ones are made, so we need to reflect that change in the database.
        # Keep track of the `challonge_id` of the Matches that are currently in
        # the database, and delete the rows for Matches that have been deleted
        # from the Challonge tournament.
        if tournament_obj.matches
            old_match_ids = @tournament.matches.pluck(:challonge_id)

            tournament_obj.matches.each do |m|
                s = OpenStruct.new(m["match"])

                @tournament.matches.find_or_initialize_by(challonge_id: s.id).update!(s)
                old_match_ids.delete(s.id)
            end

            # If `old_match_ids` is non-empty, then those matches were deleted from
            # the tournament, so delete them from our database, too.
            if old_match_ids.present?
                @tournament.matches.where(challonge_id: old_match_ids).destroy_all
            end

            @tournament.update_group_names
        end

        redirect_to action: "show"
    end

    def edit
    end

    def update
        names = params[:team_alt_names] || []
        ids = (params[:team_ids] || []).map(&:to_i)

        # The arrays must be the same size, the IDs must be different, and all
        # IDs must refer to teams in this tournament.
        team_ids = @tournament.teams.ids

        if names.size != ids.size || ids.size != ids.uniq.size ||
           !ids.all? { |tid| team_ids.include? tid }
            head :bad_request
            return
        end

        if @tournament.set_team_alt_names(ids.zip(names).to_h) &&
           @tournament.update(tournament_params)
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

        response = @tournament.finalize!

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
