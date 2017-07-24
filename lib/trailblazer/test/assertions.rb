# module MiniTest::Assertions
module Trailblazer
  module Test
    # Evaluate value if it's a lambda, and let the caller know whether we need an
    # assert_equal or an assert.
    def self.expected(value, actual)
      value.is_a?(Proc) ? [ value.(actual), false ] : [ value, true ]
    end

    # Read the actual value from the asserted object (e.g. a model).
    def self.actual(asserted, reader, name)
       v=reader ? asserted.send(reader, name) : asserted.send(name)
       v
    end

    module Assertions
      module_function
        # tuples = defaults.merge(overrides) # FIXME: merge with above!

      # Test if all `tuples` values on `result` match the expected values.
      # @param result Object Object that exposes attributes to test
      # @param tuples Hash Key/value attribute pairs to test
      # @param options Hash Default :reader is `#[]`,
      def assert_exposes(result, tuples, reader: :[])
        tuples.each do |k, v|
          actual          = Test.actual(result, reader, k)
          expected, is_eq = Test.expected(v, actual)

          is_eq ? assert_equal( expected, actual, "Property [#{k}] mismatch" ) : assert(expected, "Actual: #{actual.inspect}.")
        end
      end
    end
  end
end
# Trailblazer::Operation::Result.infect_an_assertion :assert_result_matches, :must_match, :do_not_flip
# Object.infect_an_assertion :assert_exposes, :must_expose, :do_not_flip
