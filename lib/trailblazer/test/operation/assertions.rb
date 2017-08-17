module Trailblazer::Test::Operation
  module Assertions
    def assert_passes(operation_class, params, expected_attributes, &block)
      default_params = params_valid # FIXME.
      default_attributes = attributes_valid # FIXME.


      params = default_params.merge(params)

      assert_passes_with_model(operation_class, params, expected_attributes, &block)
    end

    # @private
    def assert_passes_with_model(operation_class, params, expected_attributes, &block) # TODO: test expected_attributes default param and explicit!
      result = operation_class.( params )

      assert_equal true, result.success?

      return yield result if block_given?  # DISCUSS: result or model?

      assert_exposes( result["model"], expected_attributes )
    end
  end
end
