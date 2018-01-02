class Match < ApplicationRecord
    belongs_to :tournament

    scope :complete?, -> { where(state: "complete") }
    scope :has_team?, ->(id) { where("team1_id = ? OR team2_id = ?", id, id) }
    scope :winner?, ->(id) { complete?.where(winner_id: id) }
    scope :loser?, ->(id) { complete?.has_team?(id).where.not(winner_id: id) }

    def complete?
        return state == "complete"
    end
end
