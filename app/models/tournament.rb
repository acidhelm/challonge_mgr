# frozen_string_literal: true

class Tournament < ApplicationRecord
    belongs_to :user
    has_many :teams, dependent: :destroy
    has_many :matches, dependent: :destroy

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: { scope: :user_id }
    validates :name, presence: true
    validates :challonge_alphanumeric_id, presence: true, uniqueness: { scope: :user_id }
    validates :state, presence: true
    validates :challonge_url, presence: true, uniqueness: { scope: :user_id }
    validates :tournament_type, presence: true
    validates :view_gold_score, numericality: { only_integer: true,
                                                greater_than_or_equal_to: 0 }
    validates :view_blue_score, numericality: { only_integer: true,
                                                greater_than_or_equal_to: 0 }
    validates :slack_notifications_channel, presence: true, if: :send_slack_notifications

    scope :underway, -> { where(state: Tournament.states_to_show) }
    scope :complete, -> { where(state: "complete") }

    def self.states_to_show
        return %w(underway group_stages_underway awaiting_review).freeze
    end

    def update!(obj)
        self.description = obj.description
        self.name = obj.name
        self.challonge_alphanumeric_id = obj.url
        self.state = obj.state
        self.challonge_url = obj.full_challonge_url
        self.tournament_type = obj.tournament_type
        self.started_at = obj.started_at
        self.gold_on_left ||= Rails.configuration.gold_on_left_default
        save!
    end

    def set_current_match(match)
        update(current_match: match.id)

        if send_slack_notifications && slack_notifications_channel.present?
            next_match = nil

            if matches.upcoming.reject(&:current_match?).present?
                next_match = matches.upcoming.reject(&:current_match?).first
            end

            TournamentsHelper.notify_match_starting(self, match, next_match)
        end
    end

    def set_match_complete(match)
        # Store the team names and scores from the just-completed match, so that
        # the viewing APIs return those values until the next match begins.
        update(current_match: nil,
               view_gold_name: match.team_name(:gold),
               view_blue_name: match.team_name(:blue),
               view_gold_score: match.team_score(:gold),
               view_blue_score: match.team_score(:blue))

        if send_slack_notifications && slack_notifications_channel.present?
            TournamentsHelper.notify_match_complete(self, match)
        end
    end

    def cabinet_color(side)
        string_id = case side
                        when :left
                            gold_on_left ? :gold_cab_name : :blue_cab_name
                        when :right
                            gold_on_left ? :blue_cab_name : :gold_cab_name
                        else
                            nil
                    end

        return string_id ? I18n.t(string_id) : ""
    end
end
