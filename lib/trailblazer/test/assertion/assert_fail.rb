module Trailblazer
  module Test
    module Assertion
      module AssertFail
        module_function

        extend AssertPass::Utils

        # {expected_errors} can be nil when using the {#assert_fail} block syntax.
        def call(activity, ctx, expected_errors=nil, test:, invoke:, **kws)
          signal, ctx, _ = invoke.(ctx, operation: activity) # FIXME: remove kws?

          assert_fail_with_model(signal, ctx, expected_errors: expected_errors, test: test, operation: activity, **kws)
        end

        # @private
        def assert_fail_with_model(signal, ctx, test:, **options)
          assert_after_call(ctx, **options) do |ctx|

            test.assert_equal *arguments_for_assert_fail(signal), error_message_for_assert_fail_after_call(signal, ctx, **options)

            if options[:expected_errors]
              # TODO: allow error messages from somewhere else.
              # only test _if_ errors are present, not the content.
              colored_errors = colored_errors_for(ctx)

              test.assert_equal *arguments_for_assert_contract_errors(signal, ctx, contract_name: :default, **options), "Actual contract errors: #{colored_errors}"
            end
          end
        end

        def arguments_for_assert_fail(signal)
          return false, Assertion::SUCCESS_TERMINI.include?(signal.to_h[:semantic]) # FIXME: same logic as in {#assert_pass}.
        end

        def arguments_for_assert_contract_errors(signal, ctx, contract_name:, expected_errors:, **)
          with_messages = expected_errors.is_a?(Hash)

          raise ExpectedErrorsTypeError, "expected_errors has to be an Array or Hash" unless expected_errors.is_a?(Array) || with_messages # TODO: test me!

          errors = ctx["contract.#{contract_name}"].errors.messages # TODO: this will soon change with the operation Errors object.

          if with_messages
            expected_errors = expected_errors.collect { |k, v| [k, Array(v)] }.to_h

            return expected_errors, errors
          else
            return expected_errors.sort, errors.keys.sort
          end
        end

        def error_message_for_assert_fail_after_call(signal, ctx, operation:, **)
          %{{#{operation}} didn't fail, it passed}
        end
      end
    end
  end
end
