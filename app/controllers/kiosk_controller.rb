class KioskController < ApplicationController
    before_action :set_tournament

    def show
        @refresh_time = params[:t] || Rails.configuration.kiosk_refresh_time
    end

    protected
    def set_tournament
        @tournament = Tournament.readonly.where("lower(challonge_alphanumeric_id) = ?",
                                                params[:id].downcase).first

        render_not_found_error(:tournament) if @tournament.blank?
    end
end
