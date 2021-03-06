# frozen_string_literal: true

class ApplicationController < ActionController::Base
    include SessionsHelper

    protect_from_forgery with: :exception

    # Checks that a user is logged in.  Actions that require the user to be
    # logged in must call this function as a `before_action` filter.
    def require_login
        if !logged_in?
            store_location
            flash[:notice] = I18n.t("errors.login_required")
            redirect_to login_url
        end
    end

    # Checks that a user is the same as the currently-logged-in user.  Actions
    # that require the user to be logged in must call this function as a
    # `before_action` filter.
    # This renders an error if the user types in, say, "/users/123/tournament/456"
    # when they own tournament 456 but their user ID is not 123.
    def correct_user?
        if !current_user?(@user)
            render plain: I18n.t("errors.page_access_denied"), status: :forbidden
        end
    end

    # Renders a 404 error with a message saying that an object was not found.
    # The parameter can be `:match`, `:tournament`, or `:user`.
    def render_not_found_error(type)
        string_id = case type
                        when :match
                            "errors.match_not_found"
                        when :tournament
                            "errors.tournament_not_found"
                        when :user
                            "errors.user_not_found"
                    end

        render plain: I18n.t(string_id), status: :not_found
    end

    private

    def set_tournament_from_slug
        # Challonge treats tournament slugs as case-insensitive, so we use a
        # case-insensitive search, too.
        #
        # FIXME: This breaks down if the same tournament is present in multiple
        # users' accounts.  For now, pick the tournament that was modified most
        # recently, under the assumption that that one is being used by the stream
        # tech.
        # The real fix might be to replace the slug param with the `Tournament`
        # ID.  I liked using the slug for the spectator view because people can
        # remember a string like "GDC4" more easily than a number.  Using a string
        # also doesn't expose database IDs.  But that feature isn't getting used
        # AFAIK, so it prolly doesn't matter.
        # It certainly doesn't matter for the kiosk, because someone in the
        # venue will set it up once and forget it.
        @tournament = Tournament.readonly.where("lower(challonge_alphanumeric_id) = ?",
                                                params[:id].downcase).
                                          order(updated_at: :desc).first

        render_not_found_error(:tournament) if @tournament.blank?
    end

    # Takes a response object from a Challonge API call, and returns true if
    # the response indicates an error.  In that case, the function yields an
    # error message, which the caller should use to render an error.
    # For example:
    #     resp = call_a_challonge_api
    #
    #     return if api_failed?(resp) do |msg|
    #         render plain: msg, status: 400
    #     end
    def api_failed?(response)
        return false unless response.try(:key?, :error)

        if block_given?
            msg = if response.dig(:error, :http_code) == 401
                      I18n.t("notices.auth_error")
                  else
                      response.dig(:error, :message)
                  end

            yield msg
        end

        return true
    end
end
