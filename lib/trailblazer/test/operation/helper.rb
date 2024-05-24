module Trailblazer::Test::Operation
  module Helper
    def call(operation_class, **args, &block)
      call!(operation_class, args, &block)
    end

    def factory(operation_class, **args, &block)
      call!(operation_class, args.merge(raise_on_failure: true), &block)
    end

    def mock_step(operation_class, id:, subprocess: nil, subprocess_path: nil, &block)
      raise ArgumentError, "Missing block: `mock_step` requires a block." if block.nil?

      override = ->(*) { step block, replace: id, id: id }

      return Class.new(operation_class, &override) if subprocess_path.nil?

      # Remove below check in 1.0.0
      if subprocess
        subprocess_path = [subprocess, *subprocess_path]
        Trailblazer::Activity::Deprecate.warn caller_locations[0], ":subprocess is deprecated and will be removed in 1.0.0. Pass `subprocess_path: #{subprocess_path}` instead."
      end

      Trailblazer::Activity::DSL::Linear::Patch.call(operation_class, subprocess_path, override)
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
