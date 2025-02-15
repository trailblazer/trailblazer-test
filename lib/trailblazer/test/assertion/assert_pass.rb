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
            Passed.new.call(signal, ctx, **options)
            PassedWithAttributes.new.call(signal, ctx, **options)
          end
        end

        class Passed
          # Check if the operation terminates on {:success}.
          # @semi-public Used in rspec-trailblazer
          def call(signal, ctx, **options)
            expected_outcome, actual_outcome = arguments_for_assertion(signal)
            error_msg = error_message(signal, ctx, **options) # DISCUSS: compute error message before there was an error?

            outcome = assertion(expected_outcome, actual_outcome, error_msg, **options)
            return outcome, error_msg
          end

          # What needs to be compared?
          def arguments_for_assertion(signal)
            return true, Assertion::SUCCESS_TERMINI.include?(signal.to_h[:semantic])
          end

          def error_message(signal, ctx, operation:, **)
            colored_errors = Errors.colored_errors_for(ctx)

            %{{#{operation}} failed: #{colored_errors}} # FIXME: only if contract's there!
          end

          def assertion(expected_outcome, actual_outcome, error_msg, test:, **)
            test.assert_equal(
              expected_outcome,
              actual_outcome,
              error_msg
            )
          end
        end

        # @semi-public Used in rspec-trailblazer
        class PassedWithAttributes
          def call(signal, ctx, **options)
            model = model_for(ctx, **options)

            outcome, error_msg = assertion(ctx, **options, model: model)
            return outcome, error_msg
          end

          # DISCUSS: should we default options like {:model_at} here?
          def model_for(ctx, model_at: :model, **)
            ctx[model_at]
          end

          def assertion(ctx, model:, expected_model_attributes:, test:, **)
            test.assert_exposes(model, expected_model_attributes)
          end
        end

        module Utils
          # @private
          def assert_after_call(ctx, user_block:, **kws)
            yield(ctx)

            user_block.call(ctx) if user_block

            ctx
          end
        end # Utils

        module Errors
          module_function

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
        end

        extend Utils
      end
    end
  end
end
