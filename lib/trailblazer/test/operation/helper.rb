module Trailblazer::Test::Operation
  module Helper
    def call(operation_class, **args, &block)
      call!(operation_class, args, &block)
    end

    def factory(operation_class, **args, &block)
      call!(operation_class, args.merge(raise_on_failure: true), &block)
    end

    # @private
    def call!(operation_class, raise_on_failure: false, **args)
      operation_class.trace(**args).tap do |result|
        unless result.success?

          msg = "factory(#{operation_class}) has failed"

          unless result["contract.default"].nil? # should we allow to change contract name?
            if result["contract.default"].errors.messages.any?
              msg += " due to validation errors: #{result["contract.default"].errors.messages}"
            end
          end

          if raise_on_failure
            result.wtf?
            raise OperationFailedError, msg
          end
        end

        yield result if block_given?

        result
      end
    end

    class OperationFailedError < RuntimeError; end
  end
end
