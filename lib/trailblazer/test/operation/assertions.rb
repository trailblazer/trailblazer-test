module Trailblazer::Test::Operation
  module Assertions
    # @needs params_pass
    # @needs attributes_pass
    def assert_pass(operation_class, params, expected_attributes, default_params: params_pass, default_attributes: attrs_pass, &block)
      input_params        = default_params.merge( params )
      expected_attributes = default_attributes.merge( expected_attributes )

      assert_passes_with_model(operation_class, input_params, expected_model_attributes: expected_attributes, &block)
    end

    # @private
    def assert_passes_with_model(operation_class, params, expected_model_attributes:{}, &user_block) # TODO: test expected_attributes default param and explicit!
      _assert_call( operation_class, assert_on_result: :success?, params: params ) do |result|
        return user_block.call(result) if user_block  # DISCUSS: result or model?

        assert_exposes( result["model"], expected_model_attributes )
      end
    end

    # @private
    def assert_fail_with_model(operation_class, params, expected_model_attributes:{}, &block)




      result["contract.default"].errors.messages.keys.must_equal [:unit_price, :currency, :invoice_number]
    end

    # @private
    def _assert_call(operation_class, assert_on_result:raise, params:raise, &block)
      result = operation_class.( params )

      assert_equal true, result.send(assert_on_result)

      yield(result)
    end
  end
end
