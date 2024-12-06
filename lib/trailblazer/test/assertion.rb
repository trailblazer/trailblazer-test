module Trailblazer
  module Test
    module Assertion
      # DISCUSS: move to Assertion::Minitest?
      # Test case instance method. Specific to Minitest.
      def assert_pass(activity, options, assertion: AssertPass, **kws, &block)
        assertion.(activity, options, test: self, user_block: block, **kws) # Forward {#assert_pass} to {AssertPass.call} or wherever your implementation sits.
      end

      # DISCUSS: move to Assertion::Minitest?
      # Test case instance method. Specific to Minitest.
      def assert_fail(activity, options, *args, assertion: AssertFail, **kws, &block)
        assertion.(activity, options, *args, test: self, user_block: block, **kws) # Forward {#assert_fail} to {AssertFail.call} or wherever your implementation sits.
      end

      # Evaluate value if it's a lambda, and let the caller know whether we need an
      # assert_equal or an assert.
      def self.expected(asserted, value, actual)
        value.is_a?(Proc) ? [value.(actual: actual, asserted: asserted), false] : [value, true]
      end

      # # Read the actual value from the asserted object (e.g. a model).
      def self.actual(asserted, reader, name)
        reader ? asserted.public_send(reader, name) : asserted.public_send(name)
      end
    end
  end
end
