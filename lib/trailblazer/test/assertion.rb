module Trailblazer
  module Test
    # Top-level entry points for end users.
    # These methods expose the syntax sugar, not the logic.
    module Assertion
      SUCCESS_TERMINI = [:success, :pass_fast] # DISCUSS: where should this be defined?

      # @private
      # Invoker for Operation
      def self.invoke_activity(operation, ctx)
        result = operation.call(ctx)

        return result.terminus, result # translate the holy {Operation::Result} object back to a normal "circuit interface" return value.
      end

      module Wtf
        # @private
        # Invoker with debugging for Operation
        def self.invoke_activity(operation, ctx)
          result = operation.wtf?(ctx)

          return result.terminus, result
        end
      end

      # DISCUSS: move to Assertion::Minitest?
      # Test case instance method. Specific to Minitest.
      def assert_pass(activity, options, assertion: AssertPass, invoke: Assertion.method(:invoke_activity), model_at: :model, **kws, &block)
        # DISCUSS: remove the injectable {:assertion} keyword for both assertions?
        # DISCUSS: {:model_at} and {:invoke_method} block actual attributes.
        assertion.(activity, options,
          test: self,
          user_block: block,
          expected_model_attributes: kws,
          model_at: model_at,
          invoke: invoke,
        ) # Forward {#assert_pass} to {AssertPass.call} or wherever your implementation sits.
      end

      # DISCUSS: move to Assertion::Minitest?
      # Test case instance method. Specific to Minitest.
      def assert_fail(activity, options, *args, assertion: AssertFail, invoke: Assertion.method(:invoke_activity), **kws, &block)
        assertion.(activity, options, *args, test: self, user_block: block, invoke: invoke, **kws) # Forward {#assert_fail} to {AssertFail.call} or wherever your implementation sits.
      end

      def assert_pass?(*args, **options, &block)
        assert_pass(*args, **options, invoke: Assertion::Wtf.method(:invoke_activity), &block)
      end

      def assert_fail?(*args, **options, &block)
        assert_fail(*args, **options, invoke: Assertion::Wtf.method(:invoke_activity), &block)
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

      # Assertions for Activity, not for Operation.
      module Activity
        def self.invoke_activity(activity, ctx)
          signal, (ctx, _) = activity.call([ctx, {}]) # call with circuit interface. https://trailblazer.to/2.1/docs/operation/#operation-internals-circuit-interface

          return signal, ctx
        end

        def self.invoke_activity_with_tracing(activity, ctx)
          signal, (ctx, _) = Developer::Wtf.invoke(activity, [ctx, {}])

          return signal, ctx
        end

        module Assert
          def assert_pass(*args, invoke: Activity.method(:invoke_activity), **options, &block)
            super(*args, **options, invoke: invoke, &block)
          end

          def assert_fail(*args, invoke: Activity.method(:invoke_activity), **options, &block)
            super(*args, **options, invoke: invoke, &block)
          end

# DISCUSS: only for Suite API so far.
          def assert_pass?(*args, **options, &block)
            assert_pass(*args, **options, invoke: Activity.method(:invoke_activity_with_tracing), &block)
          end

          def assert_fail?(*args, **options, &block)
            assert_fail(*args, **options, invoke: Activity.method(:invoke_activity_with_tracing), &block)
          end
          # TODO: test {#assert_fail?}
        end

        # include Assertion # from Test::Assert, top-level
        # include Assert # our assert_* versions.
      end
    end
  end
end
