module Trailblazer::Test
  module Helper
    module Operation
      def call(operation_class, *args)
        call!(operation_class, args)
      end

      def call!(operation_class, args, raise_on_failure:false)
        operation_class.(*args).tap do |result|
          raise OperationFailedError, "factory( #{operation_class} ) failed." if raise_on_failure && !result.success?
        end
      end

      def factory(operation_class, *args)
        call!(operation_class, args, raise_on_failure: true)
      end
    end # Operation
  end

  class OperationFailedError < RuntimeError
  end
end
