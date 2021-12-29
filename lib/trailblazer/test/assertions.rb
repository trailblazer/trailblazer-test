# module MiniTest::Assertions
module Trailblazer
  module Test
    # Evaluate value if it's a lambda, and let the caller know whether we need an
    # assert_equal or an assert.
    def self.expected(asserted, value, actual)
      value.is_a?(Proc) ? [value.(actual: actual, asserted: asserted), false] : [value, true]
    end

    # Read the actual value from the asserted object (e.g. a model).
    def self.actual(asserted, reader, name)
      reader ? asserted.public_send(reader, name) : asserted.public_send(name)
    end

    module Assertions
      # Test if all `tuples` values on `asserted` match the expected values.
      # @param asserted Object Object that exposes attributes to test
      # @param tuples Hash Key/value attribute pairs to test
      # @param options Hash Default :reader is `asserted.{name}`,
      # TODO: test err msgs!
      def assert_exposes(asserted, expected, reader = nil) # FIXME: {reader}
        passed, matches, last_failed = Assert.assert_attributes(asserted, expected, reader: reader) do |_matches, last_failed|
          name, expected_value, actual_value, _passed, is_eq, error_msg = last_failed

          is_eq ? assert_equal(expected_value, actual_value, error_msg) : assert(expected_value, error_msg)

          return false
        end

        return true
      end

      module Assert
        module_function

        def assert_attributes(asserted, expected, reader: nil, &block)
          passed, matches, last_failed = match_tuples(asserted, expected, reader: reader)

          yield matches, last_failed unless passed

          return passed, matches, last_failed
        end

        # Test if all properties match using our own {#test_equal}.
        # @private
        def match_tuples(asserted, expected, reader:)
          passed = true # goes {false} if one or more attributes didn't match.

          matches = expected.collect do |k, v|
            actual          = Test.actual(asserted, reader, k)
            expected, is_eq = Test.expected(asserted, v, actual)
# puts "@@@@@ #{actual.inspect} <>!!!!!!!!!!!! #{expected.inspect} #{is_eq}"

            is_eq ?
              [k, expected, actual, passed &= test_equal(expected, actual), is_eq, "Property [#{k}] mismatch"] :
              [k, expected, actual, passed &= test_true(expected, actual), is_eq, "Actual: #{actual.inspect}."]
          end

          [passed, matches, matches.find { |k, v, actual, passed, *| !passed }]
        end

        def test_equal(expected, actual)
          expected == actual
        end

        def test_true(expected, actual)
          !! expected
        end
      end
    end
  end
end
# Trailblazer::Operation::Result.infect_an_assertion :assert_result_matches, :must_match, :do_not_flip
# Object.infect_an_assertion :assert_exposes, :must_expose, :do_not_flip
