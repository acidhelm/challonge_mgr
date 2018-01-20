class Match < ApplicationRecord
    belongs_to :tournament

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: true
    validates :state, presence: true
    validates :round, numericality: { only_integer: true }
    # `suggested_play_order` is normally positive, but in two-stage tournaments
    # where the first stage is played in groups, it is null, so we have to
    # allow nil.
    validates :suggested_play_order, numericality: { only_integer: true, greater_than: 0 },
                                     allow_nil: true
    validates :identifier, presence: true

    scope :complete?, -> { where(state: "complete") }
    scope :winner?, ->(team) { complete?.where(winner_id: [team.challonge_id, team.group_team_ids].flatten) }
    scope :loser?, ->(team) { complete?.where(loser_id: [team.challonge_id, team.group_team_ids].flatten) }
    scope :upcoming, -> { where.not(state: "complete").order(suggested_play_order: :asc, identifier: :asc) }
    scope :completed, -> { complete?.order(suggested_play_order: :asc, identifier: :asc) }

    def update!(obj)
        self.state = obj.state
        self.team1_id = obj.player1_id
        self.team2_id = obj.player2_id
        self.winner_id = obj.winner_id
        self.loser_id = obj.loser_id
        self.round = obj.round
        self.suggested_play_order = obj.suggested_play_order
        self.identifier = obj.identifier
        self.scores_csv = obj.scores_csv
        self.underway_at = obj.underway_at
        self.team1_prereq_match_id = obj.player1_prereq_match_id
        self.team2_prereq_match_id = obj.player2_prereq_match_id
        self.team1_is_prereq_match_loser = obj.player1_is_prereq_match_loser
        self.team2_is_prereq_match_loser = obj.player2_is_prereq_match_loser

        assign_cabinets!
    end

    def complete?
        return state == "complete"
    end

    def current_match?
        return state == "open" && id == tournament.current_match
    end

    def teams_are_tbd?
        return team1_id.nil? || team2_id.nil?
    end

    def assign_cabinets!
        # If this match's teams are not TBD, and the teams have not been
        # assigned cabs yet (which means that this match just switched from
        # TBD to not-TBD), then set the teams' colors.  Team 1 defaults to
        # the left cab, and team 2 defaults to the right cab.
        if !teams_are_tbd? && !cabinets_assigned?
            if tournament.gold_on_left
                self.gold_team_id = team1_id
                self.blue_team_id = team2_id
            else
                self.gold_team_id = team2_id
                self.blue_team_id = team1_id
            end
        end
    end

    def switch_team_sides!
        temp = self.gold_team_id
        self.gold_team_id = self.blue_team_id
        self.blue_team_id = temp
    end

    def cabinets_assigned?
        return gold_team_id.present? && blue_team_id.present?
    end

    def left_team_name
        return tournament.teams.from_id(get_team_id(:left)).first&.name
    end

    def right_team_name
        return tournament.teams.from_id(get_team_id(:right)).first&.name
    end

    def left_team_score
        return 0 if scores_csv.blank?

        scores = scores_csv.partition(",")[0].split("-").map(&:to_i)

        return (get_team_id(:left) == team1_id) ? scores[0] : scores[1]
    end

    def right_team_score
        return 0 if scores_csv.blank?

        scores = scores_csv.partition(",")[0].split("-").map(&:to_i)

        return (get_team_id(:right) == team1_id) ? scores[0] : scores[1]
    end

    def left_team_won?
        return complete? && get_team_id(:left) == winner_id
    end

    def right_team_won?
        return complete? && get_team_id(:right) == winner_id
    end

    def winning_team_name
        return nil if !complete?
        return left_team_won? ? left_team_name : right_team_name
    end

    def losing_team_name
        return nil if !complete?
        return left_team_won? ? right_team_name :  left_team_name
    end

    def winning_team_score
        return left_team_won? ? left_team_score : right_team_score
    end

    def losing_team_score
        return left_team_won? ? right_team_score : left_team_score
    end

    def left_team_is_prereq_match_loser?
        team_id = get_team_id(:left)

        if team_id
            return (team_id == team1_id) ? team1_is_prereq_match_loser :
                                           team2_is_prereq_match_loser
        else
            return team1_is_prereq_match_loser
        end
    end

    def right_team_is_prereq_match_loser?
        team_id = get_team_id(:right)

        if team_id
            return (team_id == team1_id) ? team1_is_prereq_match_loser :
                                           team2_is_prereq_match_loser
        else
            return team2_is_prereq_match_loser
        end
    end

    def left_team_prereq_match_id
        team_id = get_team_id(:left)

        if team_id
            return (team_id == team1_id) ? team1_prereq_match_id :
                                           team2_prereq_match_id
        else
            return team1_prereq_match_id
        end
    end

    def right_team_prereq_match_id
        team_id = get_team_id(:right)

        if team_id
            return (team_id == team1_id) ? team1_prereq_match_id :
                                           team2_prereq_match_id
        else
            return team2_prereq_match_id
        end
    end

    def get_team_id(side)
        if side == :left
            left_team_id = tournament.gold_on_left ? gold_team_id : blue_team_id
            return left_team_id ? left_team_id : team1_id
        else
            right_team_id = tournament.gold_on_left ? blue_team_id : gold_team_id
            return right_team_id ? right_team_id : team2_id
        end
    end

    def make_scores_csv(left_score, right_score)
        if get_team_id(:left) == team1_id
            return "#{left_score}-#{right_score}"
        else
            return "#{right_score}-#{left_score}"
        end
    end

    def left_cabinet_color
        return tournament.gold_on_left ? "Gold" : "Blue"
    end

    def right_cabinet_color
        return tournament.gold_on_left ? "Blue" : "Gold"
    end

    # The `suggested_play_order` field ranges from 1 to N, which is useful for
    # identifying matches in the UI.  In the first stage of a two-stage
    # tournament, there is no `suggested_play_order` value, so use
    # `identifier` instead.
    def number
        return suggested_play_order || identifier
    end

    def round_name(capitalized: true)
        if tournament.tournament_type == "double elimination"
            winners_or_losers = round > 0 ? "Winners'" : "Losers'"
            ret = "#{winners_or_losers} round #{round.abs}"
        else
            ret = "Round #{round}"
        end

        return capitalized ? ret : ret.downcase
    end
end
