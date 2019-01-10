require "test_helper"

class UserTest < ActiveSupport::TestCase
    def setup
        @user = users(:willow)
    end

    test "Try to save a user with an illegal user_name" do
        @user.user_name = ""
        assert_not @user.save
    end

    test "Try to save a user with an empty api_key" do
        @user.api_key = ""
        assert_not @user.save
    end

    test "Try to save a user with an illegal api_key" do
        @user.api_key = "bad-api-key"
        assert_not @user.save
    end

    test "Try to save a user with an illegal subdomain" do
        @user.subdomain = "domain~!"
        assert_not @user.save
    end
end
