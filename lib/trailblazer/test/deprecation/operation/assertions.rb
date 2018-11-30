module Trailblazer::Test
  module Deprecation
    module Operation
      module Assertions
        include Trailblazer::Test::Operation::Assertions

        # @needs default_params
        # @needs default_options

        def params(default_params: self.default_params, deep_merge: true, **new_params)
          [merge_for(default_params, new_params, deep_merge), {}]
        end

        def ctx(new_params, *options)
          # need *options to allow user to do something like:
          # ctx({yeah: 'nah'}, "current_user" => Object, some: 'other' )

          # this is not greate but seems necessary using *options
          new_options = options.first || {}
          deep_merge = new_options[:deep_merge].nil? ? true : deep_merge
          new_options.delete(:deep_merge)

          ctx = merge_for(_default_options, options.first || {}, deep_merge)
          [merge_for(params[0], new_params, deep_merge), ctx]
        end

        def _default_options(options: default_options)
          options
        end

        # compatibility call for TRB 2.0
        def _call_operation(operation_class, *args)
          operation_class.(args[0][0], args[0][1])
        end

        def _model(result)
          result["model"]
        end
      end
    end
  end
end
