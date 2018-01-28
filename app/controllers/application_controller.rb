class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    include SessionsHelper

    def require_log_in
        if !logged_in?
            store_location
            flash[:notice] = "You must log in."
            redirect_to login_url
        end
    end

    def correct_user?
        if !current_user?(@user)
            render plain: "You cannot access that page.", status: :forbidden
        end
    end
end
