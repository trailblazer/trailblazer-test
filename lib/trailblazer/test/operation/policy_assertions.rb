module Trailblazer::Test::Operation
  module PolicyAssertions
    include Assertions
    # @needs params_pass
    # @needs options_pass
    def assert_policy_fail(operation_class, ctx, policy_name: "default")
      _assert_call(operation_class, ctx, user_block: nil) do |result|
        assert_equal true, result.failure?
        assert_equal true, result["result.policy.#{policy_name}"].failure?
      end
    end
  end
end
