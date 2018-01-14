class Team < ApplicationRecord
    belongs_to :tournament

    serialize :group_team_ids, Array

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: true
    validates :name, presence: true
    validates :seed, numericality: { only_integer: true, greater_than: 0 }

    scope :from_id, ->(id) { select { |team| team.challonge_id == id ||
                                             team.group_team_ids.include?(id) } }
end
