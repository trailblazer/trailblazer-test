module Trailblazer
  module Test
    module Assertion
      module AssertExposes
        # Test if all `tuples` values on `asserted` match the expected values.
        # @param asserted Object Object that exposes attributes to test
        # @param tuples Hash Key/value attribute pairs to test
        # @param options Hash Default :reader is `asserted.{name}`,
        # TODO: test err msgs!
        def assert_exposes(asserted, expected=nil, reader: nil, **options)
          expected = options.any? ? options : expected # allow passing {expected} as kwargs, too.

          _assert_exposes_for(asserted, expected, reader: reader)
        end

        # def assert_exposes_hash(asserted, expected)
        #   _assert_exposes_for(asserted, expected, reader: :[])
        # end

        # @private
        def _assert_exposes_for(asserted, expected, **options)
          passed, matches, last_failed = Assert.assert_attributes(asserted, expected, **options) do |_matches, last_failed|
            name, expected_value, actual_value, _passed, is_eq, error_msg = last_failed

            is_eq ? assert_equal(expected_value, actual_value, error_msg) : assert(expected_value, error_msg)

            return false
          end

          return true
        end

        module Assert
          module_function

          # Yields {block} if tuples don't match/failed.
          def assert_attributes(asserted, expected, reader: false, &block)
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
end
