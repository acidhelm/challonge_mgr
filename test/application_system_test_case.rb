require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
    driven_by :selenium, using: :chrome, screen_size: [800, 1000]

    def take_failed_screenshot
        false
    end
end
