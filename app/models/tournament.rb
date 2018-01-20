class Tournament < ApplicationRecord
    belongs_to :user
    has_many :teams, dependent: :destroy
    has_many :matches, dependent: :destroy

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: true
    validates :name, presence: true
    validates :challonge_alphanumeric_id, presence: true, uniqueness: true
    validates :state, presence: true
    validates :challonge_url, presence: true, uniqueness: true
    validates :tournament_type, presence: true

    scope :underway?, -> { where(state: Tournament.states_to_show) }

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
        self.gold_on_left ||= Rails.configuration.gold_on_left_default
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
        update(current_match: nil)

        if send_slack_notifications && slack_notifications_channel.present?
            TournamentsHelper.notify_match_complete(self, match)
        end
    end
end
