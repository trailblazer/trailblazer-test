module Trailblazer
  module Test
    module Assertion
      module AssertPass
        module_function

        def call(activity, ctx, invoke:, **options)
          signal, ctx, _ = invoke.(activity, ctx)

          assert_pass_with_model(signal, ctx, operation: activity, **options)
        end

        def assert_pass_with_model(signal, ctx, **options)
          assert_after_call(ctx, **options) do |ctx|
            passed?(signal, ctx, **options)
            passed_with?(signal, ctx, **options)
          end
        end

        # Check if the operation terminates on {:success}.
        # @semi-public Used in rspec-trailblazer
        def passed?(signal, ctx, test:, **options)
          test.assert_equal(*arguments_for_assert_pass(signal), error_message_for_assert_pass(signal, ctx, **options))
        end

        # @semi-public Used in rspec-trailblazer
        # DISCUSS: should we default options like {:model_at} here?
        def passed_with?(signal, ctx, model_at: :model, expected_model_attributes: {}, test:, **options)
          actual_model = model_for(ctx, model_at: model_at)

          test.assert_exposes(actual_model, expected_model_attributes)
        end

        # What needs to be compared?
        def arguments_for_assert_pass(signal)
          return true, Assertion::SUCCESS_TERMINI.include?(signal.to_h[:semantic])
        end

        def model_for(ctx, model_at:, **)
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
