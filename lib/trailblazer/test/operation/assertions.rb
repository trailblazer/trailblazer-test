require "hashie"

module Trailblazer::Test::Operation
  module Assertions
    # @needs default_params
    # @needs default_options
    # @needs expected_attrs

    def params(default_params: self.default_params, deep_merge: true, **new_params)
      {params: merge_for(default_params, new_params, deep_merge)}
    end

    def ctx(new_params, default_options: self.default_options, deep_merge: true, **options)
      new_params  = merge_for(params[:params], new_params, deep_merge)
      new_options = merge_for(default_options, options, deep_merge)

      {params: new_params, **new_options}
    end

    def assert_pass(operation_class, operation_inputs, expected_attributes, default_attributes: expected_attrs, deep_merge: true, &block)
      expected_attributes = merge_for(default_attributes, expected_attributes, deep_merge)

      assert_pass_with_model(operation_class, operation_inputs, expected_model_attributes: expected_attributes, &block)
    end

    def assert_fail(operation_class, operation_inputs, expected_errors: nil, contract_name: "default", &block)
      assert_fail_with_model(operation_class, operation_inputs, expected_errors: expected_errors, contract_name: contract_name, &block)
    end

    # @private
    # TODO: test expected_attributes default param and explicit!
    def assert_pass_with_model(operation_class, operation_inputs, expected_model_attributes: {}, &user_block)
      _assert_call(operation_class, operation_inputs, user_block: user_block) do |result|
        assert_equal true, result.success?
        assert_exposes(_model(result), expected_model_attributes)
      end
    end

    # @private
    def assert_fail_with_model(operation_class, operation_inputs, expected_errors: nil, contract_name: raise, &user_block)
      _assert_call(operation_class, operation_inputs, user_block: user_block) do |result|
        assert_equal true, result.failure?

        raise ExpectedErrorsTypeError, "expected_errors has to be an Array" unless expected_errors.is_a?(Array)

        # only test _if_ errors are present, not the content.
        errors = result["contract.#{contract_name}"].errors.messages # TODO: this will soon change with the operation Errors object.

        assert_equal expected_errors.sort, errors.keys.sort
      end
    end

    # @private
    def _assert_call(operation_class, operation_inputs, user_block: raise)
      result = _call_operation(operation_class, operation_inputs)

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
    def _call_operation(operation_class, operation_inputs)
      operation_class.(operation_inputs)
    end

    # @private
    def _model(result)
      result[:model]
    end
  end
end
