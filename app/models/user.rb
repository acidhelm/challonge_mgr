class User < ApplicationRecord
    has_many :tournaments, dependent: :destroy

    validates :user_name, presence: true
    validates :api_key, presence: true
    validates :password, presence: true, allow_nil: true

    has_secure_password

    # Returns a string containing the hash of `str`.
    def self.digest(str)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                      BCrypt::Engine.cost

        return BCrypt::Password.create(str, cost: cost).to_s
    end
end
