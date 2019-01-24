require "test_helper"

class TeamTest < ActiveSupport::TestCase
    def setup
        @team = teams(:team_1)
    end

    test "Update a team" do
        @team.name.upcase!
        @team.group_team_ids << 42
        assert @team.save
    end

    test "Try to save a team with an illegal group_team_ids" do
        @team.group_team_ids = [ "anya" ]
        assert_not @team.save

        @team.group_team_ids = [ -42 ]
        assert_not @team.save
    end

    test "Try to save a team with a duplicate challonge_id" do
        t2 = @team.dup
        assert_not t2.save
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
