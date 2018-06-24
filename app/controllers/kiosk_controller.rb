class KioskController < ApplicationController
    before_action :set_tournament

    def show
        # The user can set the refresh time by passing the time in seconds as
        # the `t` parameter.
        @refresh_time = params[:t] || Rails.configuration.kiosk_refresh_time
    end

    protected
    def set_tournament
        # Challonge treats tournament slugs as case-insensitive, so we use a
        # case-insensitive search, too.
        @tournament = Tournament.readonly.where("lower(challonge_alphanumeric_id) = ?",
                                                params[:id].downcase).first

        render_not_found_error(:tournament) if @tournament.blank?
    end
end
