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
        resp = @user.create_demo_tournament

        return if api_failed?(resp) do |msg|
            redirect_to user_tournaments_path(@user), notice: msg
        end

        redirect_to refresh_user_tournaments_path(
                      @user, autostart: resp["tournament"]["url"])
    end

    def hidedemo
        @user.update show_quick_start: false
        redirect_to user_tournaments_path(@user)
    end

    private
    def set_user
        # The `demo` and `hidedemo` actions pass the ID in the `user_id` param.
        @user = User.find(params[:id] || params[:user_id])
    rescue ActiveRecord::RecordNotFound
        render_not_found_error(:user)
    end

    def user_params
        params.require(:user).permit(:api_key, :subdomain, :password,
                                     :password_confirmation)
    end
end
