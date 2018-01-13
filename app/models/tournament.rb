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

    scope :underway?, -> { where(state: [ "underway", "group_stages_underway" ]) }
end
