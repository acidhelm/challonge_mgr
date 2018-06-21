require "test_helper"

class CheckLiveTournamentDataTest < ActionDispatch::IntegrationTest
    def setup
        @user = users(:test_user)

        if @user.user_name.blank?
            flunk "You must set the \"CHALLONGE_MGR_TEST_USER_NAME\"" \
                    " environment variable to run tests against live data." \
        end

        if @user.api_key.blank?
            flunk "You must set the \"CHALLONGE_MGR_TEST_USER_API_KEY\"" \
                    " environment variable to run tests against live data." \
        end
    end

    test "Read a user's list of tournaments" do
        VCR.use_cassette("get_tournament_list") do
            tournaments = ApplicationHelper.get_tournament_list(@user)
        end

        assert_instance_of Array, tournaments

        tournaments.each do |t|
            assert_instance_of Hash, t
            assert t.key?("tournament")
        end
    end

    test "Verify the contents of a tournament" do
        tournament = nil
        info = nil

        VCR.use_cassette("get_tournament_info") do
            # Since any Challonge user can get the info of any tournament, we
            # can get this tournament's info no matter which user's info has
            # been put in the environment variables.
            id = 4424522

            tournament = Tournament.new(challonge_id: id)
            tournament.user = @user

            info = ApplicationHelper.get_tournament_info(tournament)
        end

        assert_instance_of Hash, info

        # Read the "participants" array and create a `Team` object for each one.
        tournament_obj = OpenStruct.new(info["tournament"])
        tournament.update!(tournament_obj)

        tournament_obj.participants.map do |p|
            OpenStruct.new(p["participant"])
        end.each do |p|
            tournament.teams.new(challonge_id: p.id).update!(p)
        end

        # Read the "matches" array and create a `Match` object for each one.
        tournament_obj.matches.map do |m|
            OpenStruct.new(m["match"])
        end.each do |m|
            tournament.matches.new(challonge_id: m.id).update!(m)
        end

        # These tests aren't very interesting; we compare the tournament, teams,
        # and matches objects against static data.  We're really just verifying
        # that the format of the JSON that Challonge returns hasn't changed.
        expected_tournament = tournaments(:live_data_tournament)
        fields = %i(challonge_id name challonge_alphanumeric_id state
                    challonge_url tournament_type started_at)

        fields.each do |field|
            assert_equal expected_tournament[field], tournament[field]
        end

        expected_teams = [ teams(:live_data_team_a), teams(:live_data_team_b),
                           teams(:live_data_team_c), teams(:live_data_team_d) ]
        fields = %i(challonge_id name seed)
        sorted_teams = tournament.teams.to_a.sort_by!(&:seed)

        assert_equal expected_teams.size, sorted_teams.size

        expected_teams.each_with_index do |t, i|
            fields.each do |field|
                assert_equal t[field], sorted_teams[i][field]
            end
        end

        expected_matches = [ matches(:live_data_match_1), matches(:live_data_match_2),
                             matches(:live_data_match_3), matches(:live_data_match_4),
                             matches(:live_data_match_5), matches(:live_data_match_6),
                             matches(:live_data_match_7) ]
        fields = %i(challonge_id state team1_id team2_id winner_id loser_id
                    scores_csv identifier round suggested_play_order)
        sorted_matches = tournament.matches.to_a.sort_by!(&:suggested_play_order)

        assert_equal expected_matches.size, sorted_matches.size

        expected_matches.each_with_index do |m, i|
            fields.each do |field|
                assert_equal m[field], sorted_matches[i][field]
            end
        end
    end
end
