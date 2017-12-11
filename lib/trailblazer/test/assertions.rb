# module MiniTest::Assertions
module Trailblazer
  module Test
    module Assertions
      module_function

      # Test if all `tuples` values on `asserted` match the expected values.
      # @param asserted Object Object that exposes attributes to test
      # @param tuples Hash Key/value attribute pairs to test
      # @param options Hash Default :reader is `asserted.{name}`,
      def assert_exposes(asserted, tuples)
        expect(asserted).to have_attributes(tuples)
      end # TODO: test err msgs!
    end
  end
end
# Trailblazer::Operation::Result.infect_an_assertion :assert_result_matches, :must_match, :do_not_flip
# Object.infect_an_assertion :assert_exposes, :must_expose, :do_not_flip
