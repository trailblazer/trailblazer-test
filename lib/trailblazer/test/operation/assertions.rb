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
      kws = _normalize_kws(use_wtf, block, **kws)
      ctx = _ctx_for_params_fragment(params_fragment, **kws)

      expected_attributes = merge_for(kws[:expected_attributes], expected_attributes_to_merge, deep_merge)

      assert_pass_with_model(ctx, expected_model_attributes: expected_attributes, **kws)
    end

    def assert_fail(params_fragment, expected_errors, use_wtf=false, contract_name: "default", **kws, &block)
      kws = _normalize_kws(use_wtf, block, **kws)
      ctx = _ctx_for_params_fragment(params_fragment, **kws)

      assert_fail_with_model(ctx, expected_errors: expected_errors, contract_name: contract_name, **kws)
    end

    def Ctx(merge_with_ctx={}, exclude: false, key_in_params: self.key_in_params)
      params = key_in_params ? default_ctx[:params][key_in_params] : default_ctx[:params]

      filtered_params =
        if exclude
          params.slice(*(params.keys - exclude))
        else
          params # use original params if no filtering configured.
        end

      # FIXME: very, very redundant.
      params_for_ctx = key_in_params ? {key_in_params => filtered_params} : filtered_params

      ctx = merge_for(default_ctx, merge_with_ctx, true) # merge injections

      ctx = ctx.merge(params: params_for_ctx) # merge {:params}

      Trailblazer::Test::Context[ctx] # this signals "pass-through"
    end

    private def _ctx_for_params_fragment(params_fragment, key_in_params:, default_ctx:, **)
      return params_fragment if params_fragment.kind_of?(Trailblazer::Test::Context)
      # If {:key_in_params} is given, key the {params_fragment} with it, e.g. {params: {transaction: {.. params_fragment ..}}}
      merge_with_ctx = key_in_params ? {params: {key_in_params => params_fragment}} : {params: params_fragment}

      ctx = merge_for(default_ctx, merge_with_ctx, true)
    end

    # Gather all test case configuration. This involves reading all test `let` directives.
    private def _normalize_kws(use_wtf, block, operation: self.operation, key_in_params: self.key_in_params, default_ctx: self.default_ctx, expected_attributes: self.expected_attributes)
      kws = {
        user_block:           block,
        operation:            operation,
        default_ctx:          default_ctx,
        key_in_params:        key_in_params,
        expected_attributes:  expected_attributes,
      }

      kws[:invoke_method] = :wtf? if use_wtf

      return kws
    end

    # @private
    # TODO: test expected_attributes default param and explicit!
    def assert_pass_with_model(ctx, operation:, expected_model_attributes: {}, **kws, &user_block)
      _assert_call(operation, ctx, **kws) do |result|

        colored_errors = _colored_errors_for(result)
        assert_equal( true, result.success?, %{{#{operation}} failed: #{colored_errors}}) # FIXME: only if contract's there!

        assert_exposes(_model(result), expected_model_attributes)

        result
      end
    end

    # @private
    def assert_fail_with_model(ctx, operation:, expected_errors: nil, contract_name: raise, **kws, &user_block)
      _assert_call(operation, ctx, **kws) do |result|
        assert_equal false, result.success?

        raise ExpectedErrorsTypeError, "expected_errors has to be an Array" unless expected_errors.is_a?(Array)

        # TODO: allow error messages from somewhere else.
        # only test _if_ errors are present, not the content.
        errors = result["contract.#{contract_name}"].errors.messages # TODO: this will soon change with the operation Errors object.

        colored_errors = _colored_errors_for(result)
        assert_equal expected_errors.sort, errors.keys.sort, "Actual contract errors: #{colored_errors}"
      end
    end

    # @private
    def _colored_errors_for(result)
      # TODO: generic errors object "finding"
      errors =
        if result[:"contract.default"]
          result[:"contract.default"].errors.messages.inspect
        else
          ""
        end

      colored_errors = %{\e[33m#{errors}\e[0m}
    end

    # @private
    def _assert_call(operation_class, ctx, user_block: raise, **kws)
      result = _call_operation(operation_class, ctx, **kws)

      yield(result)
      user_block.call(result) if user_block

      result
    end

    # @private
    class ExpectedErrorsTypeError < RuntimeError; end

    # @private
    class CtxHash < Hash
      include Hashie::Extensions::DeepMerge
    end

    # @private
    def merge_for(dest, source, deep_merge)
      return dest.merge(source) unless deep_merge

      CtxHash[dest].deep_merge(CtxHash[source])
    end

    # @private
    def _call_operation(operation_class, ctx, invoke_method: :call, **)
      operation_class.send(invoke_method, ctx)
    end

    # @private
    def _model(result)
      result[:model]
    end
  end
end
