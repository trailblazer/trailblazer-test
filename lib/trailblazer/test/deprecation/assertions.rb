module Trailblazer::Test
  module Deprecation
    module Assertions
      include Trailblazer::Test::Operation::Assertions

      # compatibility call for TRB 2.0
      def _call_operation(operation_class, params)
        operation_class.(params)
      end

      def _model(result)
        result["model"]
      end
    end
  end
end
