# module MiniTest::Assertions
module Trailblazer::Test
  module Assertions
    module_function

    def assert_result_matches(result, defaults, overrides)
      tuples = defaults.merge(overrides)

      tuples.each do |k, v|
        assert( result[k] == v, %{Expected result["#{k.inspect}"] to == `#{v.inspect}`} )
      end
    end

      # tuples = defaults.merge(overrides) # FIXME: merge with above!

    # Test if all `tuples` values on `result` match the expected values.
    # @param result Object Object that exposes attributes to test
    # @param tuples Hash Key/value attribute pairs to test
    # @param options Hash Default :reader is `#[]`,
    def assert_exposes(result, tuples, reader: :[])
      tuples.each do |k, v|
        actual = reader ? result.send(reader, k) : result.send(k)

        assert( actual == v, %{Expected actual result["#{k}"] `#{actual.inspect}` == `#{v.inspect}`} )
      end
    end
  end
end
# Trailblazer::Operation::Result.infect_an_assertion :assert_result_matches, :must_match, :do_not_flip
# Object.infect_an_assertion :assert_exposes, :must_expose, :do_not_flip
