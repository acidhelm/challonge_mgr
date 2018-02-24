class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    include SessionsHelper

    def require_login
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

    def render_not_found_error(type)
        case type
            when :match
                msg = "That match was not found."
            when :tournament
                msg = "That tournament was not found."
            when :user
                msg = "That user was not found."
        end

        render plain: msg, status: :not_found
    end
end
