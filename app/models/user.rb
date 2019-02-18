# frozen_string_literal: true

class User < ApplicationRecord
    include ChallongeHelper

    has_many :tournaments, dependent: :destroy

    validates :user_name, presence: true, uniqueness: { case_sensitive: false }
    validates :api_key, presence: true
    validates :api_key, format: { with: /\A[a-zA-Z0-9]+\z/,
                                  message: I18n.t("errors.invalid_api_key") },
                        allow_blank: true
    validates :subdomain, format: { with: /\A[a-zA-Z0-9-]+\z/,
                                    message: I18n.t("errors.invalid_subdomain") },
                          allow_blank: true
    validates :show_quick_start, inclusion: { in: [ true, false ] }
    validates :password, presence: true, allow_nil: true
    has_secure_password

    attr_encrypted :api_key, key: ENV["ATTR_ENCRYPTED_KEY"]

    # Returns a string containing the hash of `str`.
    def self.digest(str)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                      BCrypt::Engine.cost

        return BCrypt::Password.create(str, cost: cost).to_s
    end

    # On success, returns an array of `tournament` objects that represent the
    # tournaments that are owned by this user.  If this user is in an organization,
    # the array also contains the tournaments that are owned by that organization.
    # On failure, returns an `error` object that describes the error.
    def get_tournaments
        return get_tournament_list(self)
    end

    # Creates and starts a demo tournament on Challonge.  The tournament is not
    # added to the database; the caller must do that.
    # On success, returns a `tournament` object that holds the properties of
    # the new tournament.
    # On failure, returns an `error` object that describes the error.
    def create_demo_tournament
        name = I18n.t("quick_start.tournament_name")
        desc = I18n.t("quick_start.tournament_desc")

        make_demo_tournament(self, name, desc)
    end
end
