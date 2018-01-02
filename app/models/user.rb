class User < ApplicationRecord
    has_many :tournaments, dependent: :destroy
end
