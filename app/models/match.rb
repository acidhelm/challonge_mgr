# frozen_string_literal: true

class Match < ApplicationRecord
    include ChallongeHelper

    belongs_to :tournament

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 }
    validates :state, presence: true
    validates :round, numericality: { only_integer: true }
    validates :identifier, presence: true
    validate :validate_scores_csv, if: proc { |m| m.scores_csv.present? }
    validate :validate_challonge_id_uniqueness
    validate :validate_team_ids
    validate :validate_winner_loser_ids

    with_options numericality: { only_integer: true, greater_than: 0 }, allow_nil: true do
        # `suggested_play_order` is normally positive, but in two-stage tournaments
        # where the first stage is played in groups, it is null.
        validates :suggested_play_order

        # These are nil in an elimination tournament when the teams are TBD.
        validates :team1_id
        validates :team2_id

        # These are nil when the match is not complete.
        validates :winner_id
        validates :loser_id

        # These are nil in round-robin tournaments, and in matches that are a
        # team's first match in an elimination tournament.
        validates :team1_prereq_match_id
        validates :team2_prereq_match_id

        # This is nil in elimination tournaments.
        validates :group_id
    end

    scope :complete, -> { where(state: "complete") }
    scope :has_team, ->(team) { where("team1_id IN (:ids) OR team2_id IN (:ids)",
                                      ids: team.all_challonge_ids) }
    scope :winner_is, ->(team) { complete.where(winner_id: team.all_challonge_ids) }
    scope :loser_is, ->(team) { complete.where(loser_id: team.all_challonge_ids) }
    scope :group_is, ->(gid) { where(group_id: gid) }
    scope :not_in_group, -> { where(group_id: nil) }
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
        ApplicationHelper.validate_param(side) do |s|
            SYMBOLS_LR.include?(s) || s.is_a?(Team)
        end

        return false if !complete?

        case side
            when :left, :right
                return get_team_id(side) == winner_id
            when Team
                return side.all_challonge_ids.include?(winner_id)
        end
    end

    # Tests whether a side is the loser of the prerequisite match for this Match.
    # We use this to build the "Winner of match N" and "Loser of match M" strings.
    # `side` can be `:left` or `:right`.
    def team_is_prereq_match_loser?(side)
        ApplicationHelper.validate_param(side, SYMBOLS_LR)

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
        ApplicationHelper.validate_param(side, SYMBOLS_LR)

        case side
            when :left
                left_team_id = tournament.gold_on_left ? gold_team_id : blue_team_id
                return left_team_id || team1_id
            when :right
                right_team_id = tournament.gold_on_left ? blue_team_id : gold_team_id
                return right_team_id || team2_id
        end
    end

    # Returns a `Team` object for the team that is on the given side, or nil
    # if no team has been assigned to that side yet.
    # `side` can be `:left` or `:right`.
    def get_team(side)
        ApplicationHelper.validate_param(side, SYMBOLS_LR)

        return tournament.teams.from_id(get_team_id(side)).first
    end

    # Returns the name of the team in a given location, or nil if no team
    # has been assigned there yet.
    # `location` can be `:left`, `:right`, `:gold`, `:blue`, `:winner`, or `:loser`.
    # If `use_alt` is true, and the team has had an alternate name set, the
    # alternate name is returned.
    def team_name(location, use_alt: false)
        ApplicationHelper.validate_param(location, SYMBOLS_LRGBWL)

        case location
            when :left, :right
                team = get_team(location)

                if use_alt
                    return team&.alt_name || team&.name
                else
                    return team&.name
                end
            when :gold
                return tournament.gold_on_left ? team_name(:left, use_alt: use_alt) :
                                                 team_name(:right, use_alt: use_alt)
            when :blue
                return tournament.gold_on_left ? team_name(:right, use_alt: use_alt) :
                                                  team_name(:left, use_alt: use_alt)
            when :winner
                return nil if !complete?
                return team_won?(:left) ? team_name(:left, use_alt: use_alt) :
                                          team_name(:right, use_alt: use_alt)
            when :loser
                return nil if !complete?
                return team_won?(:left) ? team_name(:right, use_alt: use_alt) :
                                          team_name(:left, use_alt: use_alt)
        end
    end

    # Returns the score of the team in a given location, or 0 if the match has
    # not started yet.  Also returns 0 if the caller passes `:winner` or `:loser`
    # and the match is not complete.
    # `location` can be `:left`, `:right`, `:gold`, `:blue`, `:winner`, or `:loser`.
    def team_score(location)
        ApplicationHelper.validate_param(location, SYMBOLS_LRGBWL)

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
        end
    end

    # Returns the `challonge_id` of the Match that is the prerequisite match
    # for the team on a given side.  We use this to build the "Winner of match N"
    # and "Loser of match M" strings.
    # `side` can be `:left` or `:right`.
    def team_prereq_match_id(side)
        ApplicationHelper.validate_param(side, SYMBOLS_LR)

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
        string_id = if tournament.tournament_type == "double elimination" &&
                       suggested_play_order.present?
                        if round > 0
                            capitalized ? :winners_round_cap : :winners_round
                        else
                            capitalized ? :losers_round_cap : :losers_round
                        end
                    elsif group_name.present?
                        capitalized ? :round_with_group_cap : :round_with_group
                    else
                        capitalized ? :round_cap : :round
                    end

        return I18n.t(string_id, scope: "matches.round_names", round: round.abs,
                      group: group_name)
    end

    def update!(obj)
        # These attributes have the same names as in the JSON.
        %w(state winner_id loser_id forfeited round group_id suggested_play_order
           identifier scores_csv).each do |attr|
            send("#{attr}=", obj.send(attr))
        end

        # These attributes use "team" in their names, but the JSON uses "player".
        %w(team1_id team2_id team1_prereq_match_id team2_prereq_match_id
           team1_is_prereq_match_loser team2_is_prereq_match_loser).each do |attr|
            send("#{attr}=", obj.send(attr.sub("team", "player")))
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

    # Sets the scores or the winning team for this match.
    # On success, returns a `match` object that contains the updated properties
    # of the match.
    # On failure, returns an `error` object that describes the error.
    def update_scores(left_score, right_score, winner_id)
        new_scores_csv = if winner_id.present?
                             scores_csv
                         else
                             make_scores_csv(left_score, right_score)
                         end

        return update_match(self, new_scores_csv, winner_id)
    end

    # Sets this match as started.
    # We manually set `underway_at` because the Challonge API doesn't have
    # a way to mark a match as being underway.
    def start
        update(underway_at: Time.current)
    end

    # Sets this match as no longer being played.
    def stop
        update(underway_at: nil)
    end

    def set_group_name(name)
        update(group_name: name)
    end

    def set_no_group_name
        update(group_name: nil)
    end

    protected

    def make_scores_csv(left_score, right_score)
        if get_team_id(:left) == team1_id
            return "#{left_score}-#{right_score}"
        else
            return "#{right_score}-#{left_score}"
        end
    end

    # Tests whether teams have been assigned to both cabinets for this Match.
    def cabinets_assigned?
        return gold_team_id.present? && blue_team_id.present?
    end

    def validate_scores_csv
        if scores_csv.split(",").map { |s| s !~ /\d+-\d+/ }.any?
            errors.add(:scores_csv, "is not a valid list of scores")
        end
    end

    # This method checks that there are no other Matches in this Tournament with
    # this Match's `challonge_id`.  We can't use the built-in `uniqueness`
    # validator, because the same tournament might be in the database under
    # multiple users, and that would make the `uniqueness` validator fail.
    #
    # There `where.not(id: id)` check is necessary so that we don't find our
    # own `challonge_id` when an existing Match is being updated.
    def validate_challonge_id_uniqueness
        if tournament.matches.where.not(id: id).where(challonge_id: challonge_id).any?
            errors.add(:challonge_id, "is not unique")
        end
    end

    # This method checks that `team1_id` and `team2_id` are IDs of teams that
    # are in this tournament.
    def validate_team_ids
        if team1_id && tournament.teams.from_id(team1_id).empty?
            errors.add(:team1_id, "is not a valid team ID")
        end

        if team2_id && tournament.teams.from_id(team2_id).empty?
            errors.add(:team2_id, "is not a valid team ID")
        end
    end

    def validate_winner_loser_ids
        # `winner_id` and `loser_id` must be nil if the match is not complete,
        # and they must be non-nil if the match is complete.
        if complete?
            errors.add(:winner_id, "cannot be nil in a completed match") if winner_id.nil?
            errors.add(:loser_id, "cannot be nil in a completed match") if loser_id.nil?
        else
            errors.add(:winner_id, "must be nil in an uncompleted match") if winner_id.present?
            errors.add(:loser_id, "must be nil in an uncompleted match") if loser_id.present?
        end

        # If `winner_id` and `loser_id` are set, they must equal the ID of one
        # of the teams in this match.
        team_ids = [ team1_id, team2_id ]

        if winner_id && !team_ids.include?(winner_id)
            errors.add(:winner_id, "is not a valid team ID")
        end

        if loser_id && !team_ids.include?(loser_id)
            errors.add(:loser_id, "is not a valid team ID")
        end
    end
end
