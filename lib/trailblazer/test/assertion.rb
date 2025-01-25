module Trailblazer
  module Test
    # Top-level entry points for end users.
    # These methods expose the end user syntax, not the logic.
    module Assertion
      def self.module!(receiver, activity: false, suite: false, spec: true)
        modules = [Helper::MockStep, AssertExposes]
        if suite
          modules += [Suite, Suite::Spec] if spec
          modules += [Suite, Suite::Test] if suite && !spec
        else
          modules += [Assertion]
        end

        modules += [Assertion::Activity] if activity

        receiver.include(*modules.reverse)
      end

      SUCCESS_TERMINI = [:success, :pass_fast] # DISCUSS: where should this be defined?

      # @private
      # Invoker for Operation
      def self.invoke_operation(operation, ctx)
        result = operation.call(ctx)

        return result.terminus, result # translate the holy {Operation::Result} object back to a normal "circuit interface" return value.
      end

      # @private
      # Invoker with debugging for Operation
      def self.invoke_operation_with_wtf(operation, ctx)
        result = operation.wtf?(ctx)

        return result.terminus, result
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

      # DISCUSS: move to Assertion::Minitest?
      # Test case instance method. Specific to Minitest.
      def assert_pass(activity, options, invoke: Assertion.method(:invoke_operation), model_at: :model, **kws, &block)
        # DISCUSS: {:model_at} and {:invoke_method} block actual attributes.
        AssertPass.(activity, options,
          test: self,
          user_block: block,
          expected_model_attributes: kws,
          model_at: model_at,
          invoke: invoke,
        ) # Forward {#assert_pass} to {AssertPass.call} or wherever your implementation sits.
      end

      # DISCUSS: move to Assertion::Minitest?
      # Test case instance method. Specific to Minitest.
      def assert_fail(activity, options, *args, invoke: Assertion.method(:invoke_operation), **kws, &block)
        AssertFail.(activity, options, *args, test: self, user_block: block, invoke: invoke, **kws) # Forward {#assert_fail} to {AssertFail.call} or wherever your implementation sits.
      end

      def assert_pass?(*args, **options, &block)
        assert_pass(*args, **options, invoke: Assertion.method(:invoke_operation_with_wtf), &block)
      end

      def assert_fail?(*args, **options, &block)
        assert_fail(*args, **options, invoke: Assertion.method(:invoke_operation_with_wtf), &block)
      end

      # Assertions for Activity, not for Operation.
      module Activity
        def self.invoke_activity(activity, ctx)
          signal, (ctx, _) = activity.call([ctx, {}]) # call with circuit interface. https://trailblazer.to/2.1/docs/operation/#operation-internals-circuit-interface

          return signal, ctx
        end

        def self.invoke_activity_with_task_wrap(activity, ctx)
          signal, (ctx, _) = ::Trailblazer::Activity::TaskWrap.invoke(activity, [ctx, {}]) # call with circuit interface. https://trailblazer.to/2.1/docs/operation/#operation-internals-circuit-interface

          return signal, ctx
        end

        def self.invoke_activity_with_tracing(activity, ctx)
          signal, (ctx, _) = Developer::Wtf.invoke(activity, [ctx, {}])

          return signal, ctx
        end

        def assert_pass(*args, invoke: Activity.method(:invoke_activity_with_task_wrap), **options, &block)
          super(*args, **options, invoke: invoke, &block)
        end

        def assert_fail(*args, invoke: Activity.method(:invoke_activity_with_task_wrap), **options, &block)
          super(*args, **options, invoke: invoke, &block)
        end

        def assert_pass?(*args, **options, &block)
          assert_pass(*args, **options, invoke: Activity.method(:invoke_activity_with_tracing), &block)
        end

        def assert_fail?(*args, **options, &block)
          assert_fail(*args, **options, invoke: Activity.method(:invoke_activity_with_tracing), &block)
        end
      end
    end
  end
end
