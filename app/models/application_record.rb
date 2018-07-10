# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    SYMBOLS_LR = %i(left right).freeze
    SYMBOLS_LRGBWL = %i(left right gold blue winner loser).freeze
end
