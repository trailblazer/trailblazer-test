module Trailblazer
  module Test
    module Assertion
      module AssertPass
        def assert_pass(activity, options, use_wtf: false, **expected_model_attributes, &block)
          result, ctx, kws = call_operation(options, operation: activity)

          assert_pass_with_model(result, ctx, expected_model_attributes: expected_model_attributes, test: self, user_block: block, operation: activity)
        end

        def assert_pass_with_model(result, ctx, expected_model_attributes: {}, test:, **options)
          assert_after_call(result, **options) do |result|

            test.assert_equal(*arguments_for_assert_pass(result), error_message_for_assert_pass(result, **options))
            test.send(:assert_exposes, model(result, model_at: :model, **options), expected_model_attributes)

            result
          end
        end

        # What needs to be compared?
        def arguments_for_assert_pass(result)
          return true, result.success?
        end

        # @private
        def assert_after_call(result, user_block: raise, **kws)
          yield(result)
          user_block.call(result) if user_block

          result
        end

        def call_operation(ctx, operation:, invoke_method: :call, **)
          operation.send(invoke_method, ctx)
        end

        def model(result, model_at:, **)
          result[model_at]
        end

        def error_message_for_assert_pass(result, operation:, **)
          colored_errors = colored_errors_for(result)

          %{{#{operation}} failed: #{colored_errors}} # FIXME: only if contract's there!
        end

        def colored_errors_for(result)
          # TODO: generic errors object "finding"
          errors =
            if result[:"contract.default"]
              result[:"contract.default"].errors.messages.inspect
            else
              ""
            end

          colored_errors = %{\e[33m#{errors}\e[0m}
        end
      end
    end
  end
end
