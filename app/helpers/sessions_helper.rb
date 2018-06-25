# frozen_string_literal: true

module SessionsHelper
    # Logs in the given user.
    def log_in(user)
        session[:user_id] = user.id
    end

    # Logs out the current user.
    def log_out
        session.delete(:user_id)
        @current_user = nil
    end

    # Returns the currently-logged-in user, or nil if no user is logged in.
    def current_user
        @current_user ||= User.find_by(id: session[:user_id])
        return @current_user
    end

    # Returns true if a user is logged in, false otherwise.
    def logged_in?
        return current_user.present?
    end

    # Returns true if the given user is the currently-logged-in user.
    def current_user?(user)
        return user == current_user
    end

    # Stores the URL trying to be accessed in the `session` object.
    def store_location
        session[:forwarding_url] = request.original_url if request.get?
    end

    # Redirects to the stored URL, or to a default URL if the session has no
    # stored URL.
    def redirect_back_or(default)
        redirect_to session[:forwarding_url] || default
        session.delete(:forwarding_url)
    end
end
