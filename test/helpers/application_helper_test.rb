require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
    include ApplicationHelper

    test "Test parameter validation, without a block" do
        legal_values = %i(buffy willow)

        assert_nothing_raised do
            validate_param(:buffy, legal_values)
        end

        assert_raises(ArgumentError) do
            validate_param(:alyson, legal_values)
        end
    end

    test "Test parameter validation, with a block" do
        assert_nothing_raised do
            validate_param(:tara) do |sym|
                assert_equal :tara, sym
                true
            end
        end

        assert_raises(ArgumentError) do
            validate_param(:faith) do |sym|
                assert_equal :faith, sym
                false
            end
        end
    end
end
