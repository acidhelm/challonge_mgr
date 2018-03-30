# frozen_string_literal: true

class TournamentsController < ApplicationController
    before_action :set_user, only: %i(index refresh_all)
    before_action :set_tournament, except: %i(index refresh_all view
                                              gold blue gold_score blue_score)
    before_action :set_tournament_from_alphanumeric_id,
                  only: %i(gold blue gold_score blue_score)
    before_action :require_login, except: %i(view gold blue gold_score blue_score)
    before_action :correct_user?, except: %i(view gold blue gold_score blue_score)

    # GET /tournaments
    def index
        @tournaments = @user.tournaments.underway.order(started_at: :desc)
    end

    # GET /tournaments/refresh
    def refresh_all
        ApplicationHelper.get_tournament_list(@user).map do |t|
            OpenStruct.new(t["tournament"])
        end.select do |t|
            Tournament.states_to_show.include?(t.state) ||
              @user.tournaments.where(challonge_id: t.id).exists?
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
        tournament_obj = OpenStruct.new(tournament_hash["tournament"])

        # Read the properties that we care about from the top level of the JSON,
        # and update the Tournament object.
        @tournament.update!(tournament_obj)

        # Read the "participants" array and create a Team object for each one,
        # or update the Team if it's already in the database.
        tournament_obj.participants.map do |p|
            OpenStruct.new(p["participant"])
        end.each do |p|
            @tournament.teams.find_or_initialize_by(challonge_id: p.id).update!(p)
        end

        # Read the "matches" array and create a Match object for each one, or
        # update the Match if it's already in the database.
        # If a tournament is restarted on Challonge, the old matches are deleted
        # and new ones are made, so we need to reflect that change in the database.
        # Keep track of the `challonge_id` values that are currently in the
        # database, and delete those rows if they have been deleted from the
        # tournament on Challonge.
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
            else
                name = (side == :gold) ? @tournament.view_gold_name :
                                         @tournament.view_blue_name
            end
        rescue ActiveRecord::RecordNotFound
        end

        # Remove a parenthesized part from the end of the team name.  This lets
        # the Challonge bracket have names like "Bert's Bees (PHX)", but the
        # name on the stream will be just "Bert's Bees".  That saves space on the
        # stream, which is espcially necessary with multi-scene teams that have
        # multiple cities in the name.
        return name.sub(/\(.*?\)$/, '').strip
    end

    def current_match_team_score(side)
        score = 0

        begin
            if @tournament.current_match.present?
                score = Match.find(@tournament.current_match).team_score(side)
            else
                score = (side == :gold) ? @tournament.view_gold_score :
                                          @tournament.view_blue_score
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
