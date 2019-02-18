# frozen_string_literal: true

module ApplicationHelper
    # Checks that `param` is one of the elements in `legal_values`, and if not,
    # throws an `ArgumentError`.
    # If a more-complex test is required, the caller can pass a block.  An
    # exception will be thrown if the block returns false.  When the caller
    # passes a block, `legal_values` is not used.
    def self.validate_param(param, legal_values = nil)
        if block_given?
            raise ArgumentError, "Invalid parameter: #{param}" unless yield param
        else
            raise ArgumentError,
                  "Invalid parameter: #{param}. " \
                    "Legal values are: #{legal_values}" unless legal_values.include?(param)
        end
    end
end
