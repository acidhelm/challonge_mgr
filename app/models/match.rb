class Match < ApplicationRecord
    belongs_to :tournament

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: true
    validates :state, presence: true
    # `round` is normally positive, but in double-elimination tournaments, it is
    # negative for matches that are in the losers' bracket.
    validates :round, numericality: { only_integer: true, other_than: 0 }
    # `suggested_play_order` is normally positive, but in two-stage tournaments
    # where the first stage is played in groups, it is null, so we have to
    # allow nil.
    validates :suggested_play_order, numericality: { only_integer: true, greater_than: 0 },
                                     allow_nil: true

    scope :complete?, -> { where(state: "complete") }
    scope :has_team?, ->(id) { where("team1_id = ? OR team2_id = ?", id, id) }
    scope :winner?, ->(id) { complete?.where(winner_id: id) }
    scope :loser?, ->(id) { complete?.has_team?(id).where.not(winner_id: id) }
    scope :upcoming, -> { where.not(state: "complete").order(suggested_play_order: :asc) }
    scope :completed, -> { complete?.order(suggested_play_order: :asc) }

    def complete?
        return state == "complete"
    end

    def current_match?
        # I use the `challonge_id` field for `current_match` instead of `id`
        # because the Challonge ID is easier to find than the database ID, and
        # that makes debugging easier.
        return state == "open" && challonge_id == tournament.current_match
    end

    def team1_won?
        return complete? && team1_id == winner_id
    end

    def team2_won?
        return complete? && team2_id == winner_id
    end

    def team1_score
        return scores_csv.blank? ? 0 : scores_csv.partition(",")[0].split("-")[0]
    end

    def team2_score
        return scores_csv.blank? ? 0 : scores_csv.partition(",")[0].split("-")[1]
    end

    # The `suggested_play_order` field ranges from 1 to N, which is useful for
    # identifying matches in the UI.  I don't want to refer to `suggested_play_order`
    # in views, though, even it is (currently) equal to the match number.
    def number
        return suggested_play_order
    end
end
