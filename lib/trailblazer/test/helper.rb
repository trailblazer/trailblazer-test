module Trailblazer::Test
  module Helper
    module Operation
      def call(operation_class, *args)
        call!(operation_class, args)
      end

      def call!(operation_class, args, raise_on_failure:false)
        operation_class.(*args).tap do |result|
          raise "[Trailblazer-test] #{operation_class} returned an invalid state." if raise_on_failure
        end
      end
    end # Operation
  end
end
