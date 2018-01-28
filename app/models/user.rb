class User < ApplicationRecord
    has_many :tournaments, dependent: :destroy

    validates :user_name, presence: true
    validates :api_key, presence: true
    validates :password, presence: true

    has_secure_password
end
