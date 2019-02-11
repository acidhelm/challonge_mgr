require "application_system_test_case"

class TournamentViewerTest < ApplicationSystemTestCase
    def upcoming_match_str(match)
        # U+2014 is &mdash;
        "#{match.team_name :left} \u2014 #{match.team_name :right}"
    end

    def completed_match_str(match)
        # U+2014 is &mdash;
        "#{match.team_name :left}  #{match.team_score :left} \u2014" \
          " #{match.team_score :right}  #{match.team_name :right}"
    end

    def team_record_str(tournament, team)
        wins = tournament.matches.winner_is(team).count
        losses = tournament.matches.loser_is(team).count

        "#{team.name} (#{wins} - #{losses})"
    end

    test "Check the view-tournament page" do
        tournament = tournaments(:tournament_1)

        visit view_tournament_url(tournament.challonge_alphanumeric_id)

        assert_selector "h1", exact_text: tournament.name

        # We're using a made-up tournament from the fixture, so we know that
        # all three of these tables will be present.
        assert_selector "h2", exact_text: "Upcoming matches:"

        within "table#upcoming" do
            within "thead" do
                [ "Match #", "Round", "Teams" ].each.with_index(1) do |text, i|
                    assert_selector "th:nth-child(#{i})", exact_text: text
                end
            end

            within "tbody" do
                tournament.matches.upcoming.each.with_index(1) do |match, i|
                    within "tr:nth-child(#{i})" do
                        assert_selector "td:first-child", exact_text: match.number.to_s
                        assert_selector "td:nth-child(2)", exact_text: match.round_name
                        assert_selector "td:nth-child(3)",
                                        exact_text: upcoming_match_str(match)
                    end
                end
            end
        end

        assert_selector "h2", exact_text: "Completed matches:"

        within "table#completed" do
            within "thead" do
                [ "Match #", "Round", "Teams" ].each.with_index(1) do |text, i|
                    assert_selector "th:nth-child(#{i})", exact_text: text
                end
            end

            within "tbody" do
                tournament.matches.completed.each.with_index(1) do |match, i|
                    within "tr:nth-child(#{i})" do
                        assert_selector "td:first-child", exact_text: match.number.to_s
                        assert_selector "td:nth-child(2)", exact_text: match.round_name
                        assert_selector "td:nth-child(3)",
                                        exact_text: completed_match_str(match)
                    end
                end
            end
        end

        assert_selector "h2", exact_text: "Team records:"

        within "table#team_records" do
            within "thead" do
                [ "Seed", "Team (W-L)" ].each.with_index(1) do |text, i|
                    assert_selector "th:nth-child(#{i})", exact_text: text
                end
            end

            within "tbody" do
                tournament.teams.order(seed: :asc).each.with_index(1) do |team, i|
                    within "tr:nth-child(#{i})" do
                        assert_selector "td:first-child", exact_text: team.seed.to_s
                        assert_selector "td:nth-child(2)",
                                        exact_text: team_record_str(tournament, team)
                    end
                end
            end
        end
    end
end
