require "hashie"

module Trailblazer::Test::Operation
  module Assertions

    # Defaults so tests run without tweaking (almost).
    def self.included(includer)
      includer.let(:operation)     { raise "`let(:operation) { ... }` is missing" }
      includer.let(:key_in_params) { false }
    end

    def assert_pass(params_fragment, expected_attributes, use_wtf=false, operation: self.operation, key_in_params: self.key_in_params, default_attributes: expected_attrs, default_ctx: self.default_ctx, deep_merge: true, &block)
      expected_attributes = merge_for(default_attributes, expected_attributes, deep_merge)

      # If {:key_in_params} is given, key the {params_fragment} with it, e.g. {params: {transaction: {.. params_fragment ..}}}
      merge_with_ctx = key_in_params ? {params: {key_in_params => params_fragment}} : {params: params_fragment}

      ctx = merge_for(default_ctx, merge_with_ctx, true)

      kws = {}
      kws[:invoke_method] = :wtf? if use_wtf # TODO: same for #assert_fail !

      assert_pass_with_model(operation, ctx, expected_model_attributes: expected_attributes, **kws, &block)
    end

    def assert_fail(operation_class, operation_inputs, expected_errors: nil, contract_name: "default", &block)
      assert_fail_with_model(operation_class, operation_inputs, expected_errors: expected_errors, contract_name: contract_name, &block)
    end

    # @private
    # TODO: test expected_attributes default param and explicit!
    def assert_pass_with_model(operation_class, ctx, expected_model_attributes: {}, **kws, &user_block)
      _assert_call(operation_class, ctx, user_block: user_block, **kws) do |result|

        errors = result[:"contract.default"].errors.messages.inspect
        colored_errors = %{\e[33m#{errors}\e[0m}
        assert_equal( true, result.success?, %{{#{operation_class}} failed: #{colored_errors}}) # FIXME: only if contract's there!

        assert_exposes(_model(result), expected_model_attributes)
      end
    end

    # @private
    def assert_fail_with_model(operation_class, ctx, expected_errors: nil, contract_name: raise, &user_block)
      _assert_call(operation_class, ctx, user_block: user_block) do |result|
        assert_equal true, result.failure?

        raise ExpectedErrorsTypeError, "expected_errors has to be an Array" unless expected_errors.is_a?(Array)

        # only test _if_ errors are present, not the content.
        errors = result["contract.#{contract_name}"].errors.messages # TODO: this will soon change with the operation Errors object.

        assert_equal expected_errors.sort, errors.keys.sort
      end
    end

    # @private
    def _assert_call(operation_class, ctx, user_block: raise, **kws)
      result = _call_operation(operation_class, ctx, **kws)

      return user_block.call(result) if user_block # DISCUSS: result or model?

      yield(result)

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
