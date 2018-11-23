module Trailblazer::Test
  module Operation
    module Helper
      def call(operation_class, *args)
        call!(operation_class, args)
      end

      def call!(operation_class, args, raise_on_failure: false, &block)
        operation_class.(*args).tap do |result|
          unless result.success?
            yield result if block_given?
            raise OperationFailedError, "factory( #{operation_class} ) failed." if raise_on_failure
          end
        end
      end

      def factory(operation_class, *args, &block)
        call!(operation_class, args, raise_on_failure: true, &block)
      end
    end # Helper
  end

  class OperationFailedError < RuntimeError
  end
end
