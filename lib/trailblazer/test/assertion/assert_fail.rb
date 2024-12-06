module Trailblazer
  module Test
    module Assertion
      module AssertFail
        module_function

        extend AssertPass::Utils

        def call(activity, ctx, expected_errors, use_wtf=false, test:, **kws, &block)
          result, ctx, _ = call_operation(ctx, operation: activity) # FIXME: remove kws?

          assert_fail_with_model(result, ctx, expected_errors: expected_errors, test: test, user_block: block, operation: activity)
        end

        # @private
        def assert_fail_with_model(result, ctx, test:, **options, &block)
          assert_after_call(result, **options) do |result|

            test.assert_equal *arguments_for_assert_fail(result), error_message_for_assert_fail_after_call(result, **options)


            # TODO: allow error messages from somewhere else.
            # only test _if_ errors are present, not the content.
            colored_errors = colored_errors_for(result)

            test.assert_equal *arguments_for_assert_contract_errors(result, contract_name: :default, **options), "Actual contract errors: #{colored_errors}"
          end
        end

        def arguments_for_assert_fail(result)
          return false, result.success?
        end

        def arguments_for_assert_contract_errors(result, contract_name:, expected_errors:, **)
          with_messages = expected_errors.is_a?(Hash)

          raise ExpectedErrorsTypeError, "expected_errors has to be an Array or Hash" unless expected_errors.is_a?(Array) || with_messages # TODO: test me!

          errors = result["contract.#{contract_name}"].errors.messages # TODO: this will soon change with the operation Errors object.

          if with_messages
            expected_errors = expected_errors.collect { |k, v| [k, Array(v)] }.to_h

            return expected_errors, errors
          else
            return expected_errors.sort, errors.keys.sort
          end
        end

        def error_message_for_assert_fail_after_call(result, operation:, **)
          %{{#{operation}} didn't fail, it passed}
        end
      end
    end
  end
end
