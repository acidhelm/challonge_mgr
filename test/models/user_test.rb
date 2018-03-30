require "test_helper"

class UserTest < ActiveSupport::TestCase
    def setup
        @user = users(:willow)
    end

    test "Try to save a user with an illegal challonge_id" do
        @user.user_name = ""
        assert_not @user.save
    end

    test "Try to save a user with an illegal api_key" do
        @user.api_key = ""
        assert_not @user.save
    end
end
