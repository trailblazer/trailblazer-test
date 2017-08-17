module Trailblazer::Test::Operation
  module Assertions
    def assert_passes(operation_class, params, expected_attributes, &block)
      default_params = params_valid
      default_attributes = attributes_valid # FIXME.

      result = operation_class.( default_params.merge(params) )

      assert_result_passes(result, expected_attributes, &block)
    end

    def assert_result_passes(result, expected_attributes={}, &block) # TODO: test expected_attributes default param and explicit!
      assert_equal true, result.success?

      return yield result if block_given?  # DISCUSS: result or model?

      assert_exposes( result["model"], expected_attributes )
    end
  end
end
