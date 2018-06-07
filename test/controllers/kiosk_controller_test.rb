require "test_helper"

class KioskControllerTest < ActionDispatch::IntegrationTest
    test "should get show" do
        get kiosk_show_url
        assert_response :success
    end
end
