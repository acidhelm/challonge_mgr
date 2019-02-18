# frozen_string_literal: true

class UsersController < ApplicationController
    before_action :set_user
    before_action :require_login
    before_action :correct_user?

    def show
    end

    def edit
    end

    def update
        if @user.update(user_params)
            redirect_to @user, notice: I18n.t("notices.user_updated")
        else
            render :edit
        end
    end

    def demo
        # Create a new tournament.
        name = I18n.t("quick_start.tournament_name")
        desc = I18n.t("quick_start.tournament_desc")
        slug = ""

        resp = ApplicationHelper.make_demo_tournament(@user, name, desc)

        # Add teams to the tournament.
        if !api_failed?(resp)
            slug = resp["tournament"]["url"]
            teams = (1..6).each_with_object([]) { |n, obj| obj << I18n.t("quick_start.team#{n}") }

            resp = ApplicationHelper.add_demo_teams(@user, slug, teams)
        end

        # Start the tournament
        if !api_failed?(resp)
            resp = ApplicationHelper.start_demo_tournament(@user, slug)
        end

        return if api_failed?(resp) do |msg|
            redirect_to user_tournaments_refresh_path(@user), notice: msg
        end

        redirect_to user_tournaments_refresh_path(@user, autostart: slug)
    end

    def hide_demo
        @user.update show_quick_start: false
        redirect_to user_tournaments_path(@user)
    end

    private
    def set_user
        @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render_not_found_error(:user)
    end

    def user_params
        params.require(:user).permit(:api_key, :subdomain, :password,
                                     :password_confirmation)
    end
end
