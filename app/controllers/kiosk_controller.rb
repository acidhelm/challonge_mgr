# frozen_string_literal: true

class KioskController < ApplicationController
    before_action :set_tournament_from_slug

    def show
        # The user can set the refresh time by passing the time in seconds as
        # the `t` parameter.
        @refresh_time = params[:t] || Rails.configuration.kiosk_refresh_time

        @current_match = @tournament.current_match_obj
        @on_deck_match = @tournament.matches.upcoming.first
        @in_the_hole_match = @tournament.matches.upcoming.second
    end
end
