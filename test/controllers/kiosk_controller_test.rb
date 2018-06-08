require "test_helper"

class KioskControllerTest < ActionDispatch::IntegrationTest
    setup do
        @tournament = tournaments(:one)
        @slug = @tournament.challonge_alphanumeric_id
        @bad_slug = @slug.reverse
    end

    test "View the kiosk for a tournament" do
        [ @slug, @slug.upcase ].each do |id|
            get tournament_kiosk_path(id)
            assert_response :success
        end
    end

    test "Try to view the kiosk for a non-existant tournament" do
        get view_tournament_path(@bad_slug)
        assert_response :not_found
    end

end
