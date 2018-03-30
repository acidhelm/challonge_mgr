require "test_helper"

class TeamTest < ActiveSupport::TestCase
    def setup
        @team = teams(:one)
    end

    test "Try to save a team with an illegal challonge_id" do
        @team.challonge_id = -1
        assert_not @team.save
    end

    test "Try to save a team with an illegal name" do
        @team.name = ""
        assert_not @team.save
    end

    test "Try to save a team with an illegal seed" do
        @team.seed = -1
        assert_not @team.save
    end
end
