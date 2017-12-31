class Tournament < ApplicationRecord
    belongs_to :user
    has_many :teams
end
