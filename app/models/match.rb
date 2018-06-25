# frozen_string_literal: true

class Match < ApplicationRecord
    belongs_to :tournament

    # FIXME: The uniqueness constraint should be scoped to just the ID of the
    #        user that's accessing the records.
    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 } # , uniqueness: true
    validates :state, presence: true
    validates :round, numericality: { only_integer: true }
    validates :identifier, presence: true
    validate :validate_scores_csv, if: proc { |m| m.scores_csv.present? }

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

        # This is nil in elimination tournaments.
        v.validates :group_id
    end

    scope :complete, -> { where(state: "complete") }
    scope :has_team, ->(team) { where("team1_id IN (:ids) OR team2_id IN (:ids)",
                                      ids: team.all_challonge_ids) }
    scope :winner_is, ->(team) { complete.where(winner_id: team.all_challonge_ids) }
    scope :loser_is, ->(team) { complete.where(loser_id: team.all_challonge_ids) }
    scope :current_match, -> { where.not(state: "complete").where.not(underway_at: nil) }
    scope :upcoming, -> { where.not(state: "complete").where(underway_at: nil).play_order }
    scope :completed, -> { complete.play_order }
    scope :play_order, -> { order(group_id: :asc, suggested_play_order: :asc, identifier: :asc) }

    # Tests if this Match is complete.
    def complete?
        return state == "complete"
    end

    # Returns true if this Match has at least one Team that has not been
    # assigned yet.
    def teams_are_tbd?
        return team1_id.nil? || team2_id.nil?
    end

    # Tests whether a team has won this Match.  `side` can be `:left`, `:right`,
    # or a `Team` object.
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

    # Tests whether a side is the loser of the prerequisite match for this Match.
    # We use this to build the "Winner of match N" and "Loser of match M" strings.
    # `side` can be `:left` or `:right`.
    def team_is_prereq_match_loser?(side)
        return false unless %i(left right).include?(side)

        team_id = get_team_id(side)

        if team_id
            return (team_id == team1_id) ? team1_is_prereq_match_loser :
                                           team2_is_prereq_match_loser
        else
            return (side == :left) ? team1_is_prereq_match_loser : team2_is_prereq_match_loser
        end
    end

    # Returns the challonge_id of the team on the given side.  If no team has
    # been assigned to that side yet, returns `team1_id` for the left side, and
    # `team2_id` for the right side.  If _that_ ID hasn't been set yet, because
    # prereq matches need to be played still, then this function returns nil.
    # `side` can be `:left` or `:right`.
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
    # `side` can be `:left` or `:right`.
    def get_team(side)
        case side
            when :left, :right
                return tournament.teams.from_id(get_team_id(side)).first
            else
                return nil
        end
    end

    # Returns the name of the team in a given location, or nil if no team
    # has been assigned there yet.
    # `location` can be `:left`, `:right`, `:gold`, `:blue`, `:winner`, or `:loser`.
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

    # Returns the score of the team in a given location, or 0 if the match has
    # not started yet.  Also returns 0 if the caller passes `:winner` or `:loser`
    # and the match is not complete.
    # `location` can be `:left`, `:right`, `:gold`, `:blue`, `:winner`, or `:loser`.
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

    # Returns the `challonge_id` of the Match that is the prerequisite match
    # for the team on a given side.  We use this to build the "Winner of match N"
    # and "Loser of match M" strings.
    # `side` can be `:left` or `:right`.
    def team_prereq_match_id(side)
        return nil unless %i(left right).include?(side)

        team_id = get_team_id(side)

        if team_id
            return (team_id == team1_id) ? team1_prereq_match_id :
                                           team2_prereq_match_id
        else
            return (side == :left) ? team1_prereq_match_id : team2_prereq_match_id
        end
    end

    # The `suggested_play_order` field ranges from 1 to the number of matches
    # in the bracket, which is useful for identifying matches in the UI.  In the
    # group stage of a two-stage tournament, there is no `suggested_play_order`
    # value, so use `identifier` instead.
    def number
        return suggested_play_order || identifier
    end

    # Returns a description of the round that this Match is in.  It can be one
    # of these forms:
    #   Round N
    #   Winners' round N
    #   Losers' round N
    #   Group X, round N
    #
    # The `capitalized` parameter controls whether the first word of the name
    # is capitalized.
    def round_name(capitalized: true)
        # If the tournament is double-elimination, then the round name says
        # which half of the bracket the match is in.  But if the match is in the
        # group stage of a two-stage tournament, that would be wrong.
        # We tell the difference by looking at this match's `suggested_play_order`.
        # It is present for matches in the elimination stage.
        #
        # Note that since two-stage tournaments are not officially supported by
        # the Challonge API, I'm relying on undocumented details of the JSON
        # that could change at any time.
        if tournament.tournament_type == "double elimination" &&
           suggested_play_order.present?
            if round > 0
                string_id = capitalized ? :winners_round_cap : :winners_round
            else
                string_id = capitalized ? :losers_round_cap : :losers_round
            end
        elsif group_name.present?
            string_id = capitalized ? :round_with_group_cap : :round_with_group
        else
            string_id = capitalized ? :round_cap : :round
        end

        return I18n.t(string_id, scope: "matches.round_names", round: round.abs,
                      group: group_name)
    end

    def update!(obj)
        # These attributes have the same names as in the JSON.
        %w(state winner_id loser_id forfeited round group_id suggested_play_order
           identifier scores_csv).each do |attr|
            self.send("#{attr}=", obj.send(attr))
        end

        # These attributes use "team" in their names, but the JSON uses "player".
        %w(team1_id team2_id team1_prereq_match_id team2_prereq_match_id
           team1_is_prereq_match_loser team2_is_prereq_match_loser).each do |attr|
            self.send("#{attr}=", obj.send(attr.sub("team", "player")))
        end

        # Because the Challonge API doesn't have a way for us to mark a match
        # as underway, we will usually get `nil` for `underway_at` in the JSON
        # for a match.  If that's the case, don't update this Match's
        # `underway_at` member, because we manually manage that field.
        # However, if the `underway_at` field in the JSON is not `nil`, then we
        # do save it, because that means that someone went to the bracket on the
        # Challonge site and manually marked the match as underway, and we need
        # to reflect that in the database.
        self.underway_at = obj.underway_at if obj.underway_at.present?

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

    # Tests whether teams have been assigned to both cabinets for this Match.
    def cabinets_assigned?
        return gold_team_id.present? && blue_team_id.present?
    end

    def validate_scores_csv
        if scores_csv.split(",").map { |s| s !~ /\d+-\d+/ }.any?
            errors.add(:scores_csv, "is not a valid list of scores")
        end
    end
end
