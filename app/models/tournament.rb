# frozen_string_literal: true

class Tournament < ApplicationRecord
    include ChallongeHelper

    belongs_to :user
    has_many :teams, dependent: :destroy
    has_many :matches, dependent: :destroy

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: { scope: :user_id }
    validates :name, presence: true
    validates :challonge_alphanumeric_id, presence: true, format: { with: /\A\w+\z/ },
                                          uniqueness: { scope: :user_id, case_sensitive: false }
    validates :state, presence: true
    validates :progress_meter, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                               less_than_or_equal_to: 100 }
    validates :challonge_url, presence: true,
                              uniqueness: { scope: :user_id, case_sensitive: false }
    validates :tournament_type, presence: true
    validates :subdomain, format: { with: /\A[a-zA-Z0-9-]+\z/ }, allow_blank: true
    validates :view_gold_score, numericality: { only_integer: true,
                                                greater_than_or_equal_to: 0 }
    validates :view_blue_score, numericality: { only_integer: true,
                                                greater_than_or_equal_to: 0 }
    validates :slack_notifications_channel, presence: true, if: :send_slack_notifications
    validate :validate_datetimes

    scope :underway, -> { where(state: Tournament.states_to_show) }
    scope :complete, -> { where(state: "complete") }

    # We show a tournament in the tournaments/index view only if its state is
    # one of these values.
    def self.states_to_show
        return %w(underway group_stages_underway group_stages_finalized
                  awaiting_review).freeze
    end

    def self.show_state?(state)
        return states_to_show.include?(state)
    end

    # Tests if this Tournament is complete.
    def complete?
        return state == "complete"
    end

    # Tests if this Tournament can be finalized.
    def finalizable?
        return state == "awaiting_review"
    end

    # Tests whether this Tournament is in the first stage of a two-stage tournament.
    def in_group_stage?
        return state == "group_stages_underway" || state == "group_stages_finalized"
    end

    def update!(obj)
        self.description = obj.description
        self.name = obj.name
        self.challonge_alphanumeric_id = obj.url
        self.state = obj.state
        self.progress_meter = obj.progress_meter
        self.challonge_url = obj.full_challonge_url
        self.tournament_type = obj.tournament_type
        self.started_at = obj.started_at
        self.subdomain = obj.subdomain
        self.gold_on_left ||= Rails.configuration.gold_on_left_default
        save!
    end

    # On success, returns a `tournament` object that contains the properties of
    # this tournament. The caller can also request the teams and matches in
    # the tournament.
    # On failure, returns an `error` object that describes the error.
    def get_info(get_teams:, get_matches:)
        return get_tournament_info(self, get_teams: get_teams, get_matches: get_matches)
    end

    # Finalizes this tournament.  All matches in the tournament must be complete
    # for this call to succeed.
    # On success, returns a `tournament` object that contains the properties of
    # the tournament.
    # On failure, returns an `error` object that describes the error.
    def finalize!
        return finalize_tournament(self)
    end

    # If `current_match` is set, returns the `Match` object that corresponds
    # to that match.  Otherwise, returns `nil`.
    def current_match_obj
        if current_match.nil?
            nil
        else
            matches.find_by(id: current_match)
        end
    end

    # Stores the ID of the given Match in the Tournament table, and sends a
    # Slack notification if they are turned on for this Tournament.
    def set_current_match(match)
        update(current_match: match.id)

        if send_slack_notifications && slack_notifications_channel.present?
            TournamentsHelper.notify_match_starting(self, match,
                                                    matches.upcoming.first)
        end
    end

    # Stores the names and scores of the given Match in the Tournament table, so
    # the TournamentViewer actions can return them until the next match begins.
    # Also sends a Slack notification if they are turned on for this Tournament.
    def set_match_complete(match)
        update(current_match: nil,
               view_gold_name: match.team_name(:gold, use_alt: true),
               view_blue_name: match.team_name(:blue, use_alt: true),
               view_gold_score: match.team_score(:gold),
               view_blue_score: match.team_score(:blue))

        if send_slack_notifications && slack_notifications_channel.present?
            TournamentsHelper.notify_match_complete(self, match)
        end
    end

    # Assigns group names to matches that are in a group stage.  This may not be
    # perfect; see the comments below for more info.
    # This should be called every time the Tournament's properties are re-read
    # from Challonge.
    def update_group_names
        # Set `group_name` to nil for matches that aren't in a group.
        matches.where(group_id: nil).update(group_name: nil)

        # Group names aren't exposed through the API, so we have to determine
        # the names ourselves.  Challonge appears to assign IDs that are consecutive
        # numbers (although we don't depend on them being consecutive), and then
        # names the groups in ascending order starting with "A".
        next_group_name = "A"

        group_names = matches.distinct.where.not(group_id: nil).
                        order(group_id: :asc).pluck(:group_id).
                        each_with_object({}) do |id, names|
            names[id] = next_group_name
            next_group_name = next_group_name.succ
        end

        group_names.each do |id, name|
            matches.where(group_id: id).update(group_name: name)
        end
    end

    # Sets alternate names for teams in this tournament.
    # `alt_names` is a hash where the keys are database IDs of teams, and the
    # values are the teams' alt names.  A value may be `nil` or an empty string
    # to mean that no alt name should be used for that team.
    def set_team_alt_names(alt_names)
        # Bail out if no names were passed.  This will usually happen only
        # during tests.
        return true if alt_names.blank?

        # Store each team's alternate name.  Any validation errors are copied
        # to our `errors` object.
        alt_names.each do |tid, alt_name|
            team = teams.find(tid)

            if !team.set_alt_name(alt_name.presence)
                team.errors.each { |field, msg| errors[field] << msg }
            end
        end

        return errors.empty?
    end

    # Returns the Tournament's state as a string that is suitable for use in the UI.
    # If the state is "underway", the string also shows the percentage of matches
    # that have been completed.
    def state_name
        if state != "underway"
            ActiveSupport::Inflector.humanize(state, capitalize: false)
        else
            I18n.t("tournaments.state_underway", progress: progress_meter)
        end
    end

    # Returns the color of the cabinet on the given side.  This string is suitable
    # for use in the UI.
    # `side` can be `:left` or `:right`.
    def cabinet_color(side)
        ApplicationHelper.validate_param(side, SYMBOLS_LR)

        string_id = case side
                        when :left
                            gold_on_left ? :gold_cab_name : :blue_cab_name
                        when :right
                            gold_on_left ? :blue_cab_name : :gold_cab_name
                    end

        return I18n.t(string_id)
    end

    # Returns the color of the cabinet on the given side.  If `prefix` is passed,
    # that string is prepended to the color.
    # This string is *not* suitable for use in the UI, since it is never
    # translated.  It should be used only for internal identifiers.
    # `side` can be `:left` or `:right`.
    def cabinet_color_invariant(side, prefix = "")
        ApplicationHelper.validate_param(side, SYMBOLS_LR)

        return prefix + case side
                            when :left
                                gold_on_left ? "gold" : "blue"
                            when :right
                                gold_on_left ? "blue" : "gold"
                        end
    end

    protected
    def validate_datetimes
        # We allow `started_at` to be a few seconds into the future because of
        # the quick start demo feature.  The demo tournament is created and
        # then started immediately.  If the Challonge server's clock is slightly
        # ahead of the local clock, this validation will fail unless we allow
        # for a few seconds of slop.
        if started_at.present? && started_at > 5.seconds.from_now
            errors.add(:started_at, "cannot be in the future")
        end
    end
end
