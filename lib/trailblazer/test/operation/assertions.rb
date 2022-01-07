require "hashie"
require "trailblazer/test/context"

module Trailblazer::Test::Operation
  module Assertions

    # Defaults so tests run without tweaking (almost).
    def self.included(includer)
      includer.let(:operation)            { raise "Trailblazer::Test: `let(:operation) { ... }` is missing" }
      includer.let(:key_in_params)        { false }
      includer.let(:expected_attributes)  { {} } # You need to override this in your tests.
    end

    def assert_pass(params_fragment, expected_attributes_to_merge, use_wtf=false, deep_merge: true, **kws, &block)
      Assert.assert_pass(params_fragment, expected_attributes_to_merge, use_wtf, test: self, **kws, &block)
    end

    def assert_fail(params_fragment, expected_errors, use_wtf=false, deep_merge: true, **kws, &block)
      Assert.assert_fail(params_fragment, expected_errors, use_wtf, test: self, **kws, &block)
    end

    def Ctx(*args, **kws)
      Assert.Ctx(*args, test: self, **kws)
    end


    # Provide {Assert.assert_pass} which decouples the assertion logic from the actual test framework.
    module Assert
      module_function

      def normalize_for(params_fragment, use_wtf, block, **kws)
        kws = normalize_kws(use_wtf, block, **kws)
        ctx = ctx_for_params_fragment(params_fragment, **kws)

        return ctx, kws
      end

      # Compile {ctx} from settings and run the operation.
      def call_operation_with(params_fragment, use_wtf, block=nil, **kws)
        ctx, kws = normalize_for(params_fragment, use_wtf, block, **kws)
        result  = call_operation(ctx, **kws)

        return result, ctx, kws
      end

      #@public
      def assert_pass(params_fragment, expected_attributes_to_merge, use_wtf=false, deep_merge: true, **kws, &block)
        result, ctx, kws = call_operation_with(params_fragment, use_wtf, block, **kws)

        expected_attributes = expected_attributes_for(expected_attributes_to_merge, **kws)

        assert_pass_with_model(result, ctx, expected_model_attributes: expected_attributes, **kws)
      end

      def assert_fail(params_fragment, expected_errors, use_wtf=false, **kws, &block)
        result, ctx, kws = call_operation_with(params_fragment, use_wtf, block, **kws)

        assert_fail_with_model(result, ctx, expected_errors: expected_errors, **kws)
      end

      #@private
      def ctx_for_params_fragment(params_fragment, key_in_params:, default_ctx:, **)
        return params_fragment if params_fragment.kind_of?(Trailblazer::Test::Context)
        # If {:key_in_params} is given, key the {params_fragment} with it, e.g. {params: {transaction: {.. params_fragment ..}}}
        merge_with_ctx = key_in_params ? {params: {key_in_params => params_fragment}} : {params: params_fragment}

        ctx = merge_for(default_ctx, merge_with_ctx, true)
      end

      # @private
      # Gather all test case configuration. This involves reading all test `let` directives.
      def normalize_kws(use_wtf, block, test:, operation: test.operation, expected_attributes: test.expected_attributes, contract_name: "default", model_at: :model, **options)
        kws = {
          user_block:           block,
          operation:            operation,
          expected_attributes:  expected_attributes,
          test:                 test,
          contract_name:        contract_name,
          model_at:             model_at,

          **normalize_kws_for_ctx(test: test, **options)
        }

        kws[:invoke_method] = :wtf? if use_wtf

        return kws
      end

      def normalize_kws_for_ctx(test:, key_in_params: test.key_in_params, default_ctx: test.default_ctx)
        {
          default_ctx:          default_ctx,
          key_in_params:        key_in_params,
        }
      end

      # @private
      def assert_pass_with_model(result, ctx, expected_model_attributes: {}, test:, **options)
        assert_after_call(result, **options) do |result|

          test.assert_equal(*arguments_for_assert_pass(result), error_message_for_assert_pass(result, **options))
          test.send(:assert_exposes, model(result, **options), expected_model_attributes)

          result
        end
      end

      # What needs to be compared?
      def arguments_for_assert_pass(result)
        return true, result.success?
      end

      def arguments_for_assert_fail(result)
        return false, result.success?
      end


      def error_message_for_assert_pass(result, operation:, **)
        colored_errors = colored_errors_for(result)

        %{{#{operation}} failed: #{colored_errors}} # FIXME: only if contract's there!
      end

      def error_message_for_assert_fail_after_call(result, operation:, **)
        %{{#{operation}} didn't fail, it passed}
      end

      # FIXME: when {deep_merge: true} the result hash contains subclassed AR classes instead of the original ones.
      #        when we got this sorted we can allows deep merging here, too.
      def expected_attributes_for(expected_attributes_to_merge, expected_attributes:, deep_merge: false, **)
        _expected_attributes = merge_for(expected_attributes, expected_attributes_to_merge, deep_merge)
      end

      # @private
      def assert_fail_with_model(result, ctx, test:, **options, &user_block)
        assert_after_call(result, **options) do |result|

          test.assert_equal *arguments_for_assert_fail(result), error_message_for_assert_fail_after_call(result, **options)


          # TODO: allow error messages from somewhere else.
          # only test _if_ errors are present, not the content.
          colored_errors = colored_errors_for(result)

          test.assert_equal *arguments_for_assert_contract_errors(result, **options), "Actual contract errors: #{colored_errors}"
        end
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

      # @private
      # @private
      def assert_after_call(result, user_block: raise, **kws)
        yield(result)
        user_block.call(result) if user_block

        result
      end

      def call_operation(ctx, operation:, invoke_method: :call, **)
        operation.send(invoke_method, ctx)
      end

      # @private
      class CtxHash < Hash
        include Hashie::Extensions::DeepMerge
      end

      # @private
      def merge_for(dest, source, deep_merge)
        return dest.merge(source) unless deep_merge

        CtxHash[dest].deep_merge(CtxHash[source]) # FIXME: this subclasses ActiveRecord classes in dest like {class: ReportSubscription}
      end

      # @private
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

      def model(result, model_at:, **)
        result[model_at]
      end

      def Ctx(merge_with_ctx={}, exclude: false, merge: true, **kws)
        if merge
          options       = normalize_kws_for_ctx(**kws)
          key_in_params = options[:key_in_params]
          default_ctx   = options[:default_ctx]

          # Extract {:params} from {default_ctx}
          default_params = key_in_params ? default_ctx[:params][key_in_params] : default_ctx[:params]

          # Remove {:exclude} variables from the {params:} part
          filtered_default_params =
            if exclude
              default_params.slice(*(default_params.keys - exclude))
            else
              default_params # use original params if no filtering configured.
            end

          # FIXME: very, very redundant.
          default_params_for_ctx = key_in_params ? {key_in_params => filtered_default_params} : filtered_default_params

          ctx = default_ctx.merge({params: default_params_for_ctx})
        else # FIXME: if/else here sucks.
          ctx = {}
        end

        ctx = Assert.merge_for(ctx, merge_with_ctx, true) # merge injections

        Trailblazer::Test::Context[ctx] # this signals "pass-through"
      end
    end # Assert

    # @private
    class ExpectedErrorsTypeError < RuntimeError; end
  end
end
