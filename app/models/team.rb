class Team < ApplicationRecord
    belongs_to :tournament

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: true
    validates :name, presence: true
    validates :seed, numericality: { only_integer: true, greater_than: 0 }
end
