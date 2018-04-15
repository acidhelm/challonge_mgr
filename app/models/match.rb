# frozen_string_literal: true

class Match < ApplicationRecord
    belongs_to :tournament

    # FIXME: The uniqueness constraint should be scoped to just the ID of the
    #        user that's accessing the records.
    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 } # , uniqueness: true
    validates :state, presence: true
    validates :round, numericality: { only_integer: true }
    validates :identifier, presence: true
    validate :scores_csv, :validate_scores_csv

    with_options numericality: { only_integer: true, greater_than: 0 }, allow_nil: true do |v|
        # `suggested_play_order` is normally positive, but in two-stage tournaments
        # where the first stage is played in groups, it is null.
        v.validates :suggested_play_order

        # These are nil in an elimination tournament when the teams are TBD.
        v.validates :team1_id
        v.validates :team2_id

        # These are nil when the match is not complete.
        v.validates :winner_id
        v.validates :loser_id

        # These are nil in round-robin tournaments.
        v.validates :team1_prereq_match_id
        v.validates :team2_prereq_match_id
    end

    scope :complete, -> { where(state: "complete") }
    scope :has_team, ->(team) { where("team1_id IN (:ids) OR team2_id IN (:ids)",
                                      ids: team.all_challonge_ids) }
    scope :winner_is, ->(team) { complete.where(winner_id: team.all_challonge_ids) }
    scope :loser_is, ->(team) { complete.where(loser_id: team.all_challonge_ids) }
    scope :upcoming, -> { where.not(state: "complete").order(suggested_play_order: :asc, identifier: :asc) }
    scope :completed, -> { complete.order(suggested_play_order: :asc, identifier: :asc) }

    def complete?
        return state == "complete"
    end

    def current_match?
        return state == "open" && id == tournament.current_match
    end

    def teams_are_tbd?
        return team1_id.nil? || team2_id.nil?
    end

    def team_won?(side)
        return false if !complete?

        case side
            when :left, :right
                return get_team_id(side) == winner_id
            when Team
                return side.all_challonge_ids.include?(winner_id)
            else
                return false
        end
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

    # Returns the challonge_id of the team on the given side.  If no team has
    # been assigned to that side yet, returns `team1_id` for the left side, and
    # `team2_id` for the right side.  If _that_ ID hasn't been set yet, because
    # prereq matches need to be played still, then this function returns nil.
    def get_team_id(side)
        case side
            when :left
                left_team_id = tournament.gold_on_left ? gold_team_id : blue_team_id
                return left_team_id ? left_team_id : team1_id
            when :right
                right_team_id = tournament.gold_on_left ? blue_team_id : gold_team_id
                return right_team_id ? right_team_id : team2_id
            else
                return nil
        end
    end

    # This returns nil if no team has been assigned to the side yet.
    def get_team(side)
        case side
            when :left, :right
                return tournament.teams.from_id(get_team_id(side)).first
            else
                return nil
        end
    end

    # This returns nil if no team has been assigned to `location` yet.
    def team_name(location)
        case location
            when :left, :right
                return get_team(location)&.name
            when :gold
                return tournament.gold_on_left ? team_name(:left) : team_name(:right)
            when :blue
                return tournament.gold_on_left ? team_name(:right) : team_name(:left)
            when :winner
                return nil if !complete?
                return team_won?(:left) ? team_name(:left) : team_name(:right)
            when :loser
                return nil if !complete?
                return team_won?(:left) ? team_name(:right) : team_name(:left)
            else
                return nil
        end
    end

    # When the caller passes `:left` or `:right`, this returns 0 if the match
    # has not begun yet.  When the caller passes `:winner` or `:loser`, this
    # returns 0 if the match is not complete.
    def team_score(location)
        case location
            when :left, :right
                return 0 if scores_csv.blank?

                scores = scores_csv.partition(",")[0].split("-").map(&:to_i)

                return (get_team_id(location) == team1_id) ? scores[0] : scores[1]
            when :gold
                return tournament.gold_on_left ? team_score(:left) : team_score(:right)
            when :blue
                return tournament.gold_on_left ? team_score(:right) : team_score(:left)
            when :winner
                return 0 if !complete?
                return team_won?(:left) ? team_score(:left) : team_score(:right)
            when :loser
                return 0 if !complete?
                return team_won?(:left) ? team_score(:right) : team_score(:left)
            else
                return 0
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

    # The `suggested_play_order` field ranges from 1 to N, which is useful for
    # identifying matches in the UI.  In the first stage of a two-stage
    # tournament, there is no `suggested_play_order` value, so use
    # `identifier` instead.
    def number
        return suggested_play_order || identifier
    end

    def round_name(capitalized: true)
        if tournament.tournament_type == "double elimination"
            if round > 0
                string_id = capitalized ? :winners_round_cap : :winners_round
            else
                string_id = capitalized ? :losers_round_cap : :losers_round
            end
        else
            string_id = capitalized ? :round_cap : :round
        end

        return I18n.t(string_id, scope: "matches.round_names", round: round.abs)
    end

    def update!(obj)
        self.state = obj.state
        self.team1_id = obj.player1_id
        self.team2_id = obj.player2_id
        self.winner_id = obj.winner_id
        self.loser_id = obj.loser_id
        self.forfeited = obj.forfeited
        self.round = obj.round
        self.suggested_play_order = obj.suggested_play_order
        self.identifier = obj.identifier
        self.scores_csv = obj.scores_csv
        self.underway_at = obj.underway_at
        self.team1_prereq_match_id = obj.player1_prereq_match_id
        self.team2_prereq_match_id = obj.player2_prereq_match_id
        self.team1_is_prereq_match_loser = obj.player1_is_prereq_match_loser
        self.team2_is_prereq_match_loser = obj.player2_is_prereq_match_loser

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

        save!
    end

    def switch_team_sides!
        self.gold_team_id, self.blue_team_id = blue_team_id, gold_team_id
        save!
    end

    def make_scores_csv(left_score, right_score)
        if get_team_id(:left) == team1_id
            return "#{left_score}-#{right_score}"
        else
            return "#{right_score}-#{left_score}"
        end
    end

    protected
    def cabinets_assigned?
        return gold_team_id.present? && blue_team_id.present?
    end

    def validate_scores_csv
        if scores_csv.split(",").map { |s| s !~ /\d+-\d+/ }.any?
            errors.add(:scores_csv, "is not a valid list of scores")
        end
    end
end
