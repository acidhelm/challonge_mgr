require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
    include ApplicationHelper

    test "Test parameter validation" do
        legal_values = %i(buffy willow)

        assert_nothing_raised do
            validate_param(:buffy, legal_values)
        end

        assert_raises(ArgumentError) do
            validate_param(:alyson, legal_values)
        end
    end
end
