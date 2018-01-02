class Tournament < ApplicationRecord
    belongs_to :user
    has_many :teams, dependent: :destroy
    has_many :matches, dependent: :destroy
end
