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
    def assert_passes_with_model(operation_class, params, expected_model_attributes:{}, &block) # TODO: test expected_attributes default param and explicit!
      result = operation_class.( params )

      assert_equal true, result.success?

      return yield result if block_given?  # DISCUSS: result or model?

      assert_exposes( result["model"], expected_model_attributes )
    end
  end
end
