module Trailblazer::Test::Operation
  module Assertions
    # @needs params_pass
    # @needs attributes_pass
    def assert_pass(operation_class, params, expected_attributes, default_params: params_pass, default_attributes: attrs_pass, &block)
      input_params        = default_params.merge( params )
      expected_attributes = default_attributes.merge( expected_attributes )

      assert_pass_with_model(operation_class, input_params, expected_model_attributes: expected_attributes, &block)
    end

    def assert_fail(operation_class, params, expected_errors, default_params: params_pass, default_attributes: attrs_pass, &block)
      input_params        = default_params.merge( params )
      # expected_attributes = default_attributes.merge( expected_attributes )

      # assert_fails_with_model(operation_class, input_params, expected_model_attributes: expected_attributes, &block)
      assert_fail_with_model(operation_class, input_params, expected_errors: expected_errors, &block)
    end

    # @private
    def assert_pass_with_model(operation_class, params, expected_model_attributes:{}, &user_block) # TODO: test expected_attributes default param and explicit!
      _assert_call( operation_class, params: params, user_block: user_block ) do |result|
        assert_equal true, result.success?
        assert_exposes( result["model"], expected_model_attributes )
      end
    end

    # @private
    def assert_fail_with_model(operation_class, params, expected_errors:raise, expected_model_attributes:{}, &user_block)
      _assert_call( operation_class, params: params, user_block: user_block ) do |result|
        assert_equal true, result.failure?

        if expected_errors.is_a?(Array) # only test _if_ errors are present, not the content.
          errors = result["contract.default"].errors.messages # TODO: this will soon change with the operation Errors object.

          assert_equal expected_errors.sort, errors.keys.sort
        else
          raise "not implemented, yet"
        end
      end
    end

    # @private
    def _assert_call(operation_class, params:raise, user_block:raise, &block)
      result = operation_class.( params )

      return user_block.call(result) if user_block  # DISCUSS: result or model?

      yield(result)

      result
    end
  end
end
