# frozen_string_literal: true

class SessionsController < ApplicationController
    def new
    end

    def create
        user = User.where("lower(user_name) = ?",
                          params.dig(:session, :user_name)&.downcase).first

        if user&.authenticate(params.dig(:session, :password))
            log_in(user)
            redirect_back_or refresh_user_tournaments_path(user)
        else
            flash.now[:notice] = I18n.t("errors.login_failed")
            render :new
        end
    end

    def destroy
        log_out
        redirect_to root_url
    end
end
