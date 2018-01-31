class SessionsController < ApplicationController
    def new
    end

    def create
        user = User.where("lower(user_name) = ?",
                          params.dig(:session, :user_name)&.downcase).first

        if user&.authenticate(params.dig(:session, :password))
            log_in(user)
            redirect_back_or user_tournaments_refresh_path(user)
        else
            flash.now[:notice] = "The user name or password was incorrect."
            render :new
        end
    end

    def destroy
        log_out
        redirect_to root_url
    end
end
