module Trailblazer
  module Test
    module Assertion
      module AssertPass
        module_function

        def call(activity, ctx, invoke:, model_at: :model, test:, user_block:, expected_model_attributes:)
          signal, ctx, _ = invoke.(activity, ctx)

          assert_pass_with_model(signal, ctx, expected_model_attributes: expected_model_attributes, test: test, user_block: user_block, model_at: model_at, operation: activity)
        end

        def assert_pass_with_model(signal, ctx, expected_model_attributes: {}, test:, **options)
          assert_after_call(ctx, **options) do |ctx|
            test.assert_equal(*arguments_for_assert_pass(signal), error_message_for_assert_pass(signal, ctx, **options))

            test.send(:assert_exposes, model(ctx, **options), expected_model_attributes)
          end
        end

        # What needs to be compared?
        def arguments_for_assert_pass(signal)
          return true, Assertion::SUCCESS_TERMINI.include?(signal.to_h[:semantic])
        end

        def model(ctx, model_at:, **)
          ctx[model_at]
        end

        def error_message_for_assert_pass(signal, ctx, operation:, **)
          colored_errors = colored_errors_for(ctx)

          %{{#{operation}} failed: #{colored_errors}} # FIXME: only if contract's there!
        end

        module Utils
          # @private
          def assert_after_call(ctx, user_block:, **kws)
            yield(ctx)

            user_block.call(ctx) if user_block

            ctx
          end

          def colored_errors_for(ctx)
            # TODO: generic errors object "finding"
            errors =
              if ctx[:"contract.default"]
                ctx[:"contract.default"].errors.messages.inspect
              else
                ""
              end

            colored_errors = %{\e[33m#{errors}\e[0m}
          end
        end # Utils

        extend Utils
      end
    end
  end
end
