class Team < ApplicationRecord
    belongs_to :tournament

    serialize :group_team_ids, Array

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: true
    validates :name, presence: true
    validates :seed, numericality: { only_integer: true, greater_than: 0 }

    def self.from_id(id)
        return where(challonge_id: id) if Team.where(challonge_id: id).any?

        Team.find_each do |t|
            return where(challonge_id: t.challonge_id) if t.group_team_ids.include? id
        end

        return Team.none
    end
end
