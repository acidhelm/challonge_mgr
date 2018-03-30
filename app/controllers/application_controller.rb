# frozen_string_literal: true

class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    include SessionsHelper

    def require_login
        if !logged_in?
            store_location
            flash[:notice] = I18n.t("errors.login_required")
            redirect_to login_url
        end
    end

    def correct_user?
        if !current_user?(@user)
            render plain: I18n.t("errors.page_access_denied"), status: :forbidden
        end
    end

    def render_not_found_error(type)
        case type
            when :match
                msg = I18n.t("errors.match_not_found")
            when :tournament
                msg = I18n.t("errors.tournament_not_found")
            when :user
                msg = I18n.t("errors.user_not_found")
        end

        render plain: msg, status: :not_found
    end
end
