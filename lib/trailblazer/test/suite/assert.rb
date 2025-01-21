module Trailblazer
  module Test
    # Offers the assertions `#assert_pass` and friends but with a configuration "DSL".
    # That means you can write super short and concise test cases using the defaulting
    # in this module.
    module Suite
      # Provide {Assert.assert_pass} and {Assert.assert_fail} functions which decouple
      # the assertion logic from the actual test framework.
      # They are called from the {Suite#assert_pass} helpers.
      module Assert
        module_function

        # @semi-public (for rspec-trailblazer).
        def normalize_for(params_fragment, **kws)
          kws = normalize_kws(**kws)
          ctx = ctx_for_params_fragment(params_fragment, **kws)

          return ctx, kws
        end

        #@public
        def assert_pass(params_fragment, deep_merge: true, assertion:, expected_attributes_to_merge:, **kws) # TODO: remove kws.
          ctx, kws = normalize_for(params_fragment, **kws) # compute input, .

          expected_attributes = expected_attributes_for(expected_attributes_to_merge, **kws) # compute "output", expected model attributes.

          activity = kws[:operation]  # FIXME.

          assertion.(activity, ctx, expected_model_attributes: expected_attributes, **kws)
        end

        def assert_fail(params_fragment, expected_errors, assertion:, **kws)
          ctx, kws = normalize_for(params_fragment, **kws)
          activity = kws[:operation]  # FIXME.

          assertion.(activity, ctx, expected_errors, **kws)
        end

        # @semi-public used in rspec-trailblazer.
        def ctx_for_params_fragment(params_fragment, key_in_params:, default_ctx:, **)
          return params_fragment if params_fragment.kind_of?(Trailblazer::Test::Context)
          # If {:key_in_params} is given, key the {params_fragment} with it, e.g. {params: {transaction: {.. params_fragment ..}}}
          merge_with_ctx = key_in_params ? {params: {key_in_params => params_fragment}} : {params: params_fragment}

          ctx = Suite.merge_for(default_ctx, merge_with_ctx, true)
        end

        # @private
        # Gather all test case configuration. This involves reading all test `let` directives.
        def normalize_kws(user_block:, test:, operation: test.operation, contract_name: "default", invoke: Assertion.method(:invoke_operation), **options)
          kws = {
            operation:            operation,
            test:                 test,
            contract_name:        contract_name,
            user_block:           user_block,
            invoke: invoke,

            **normalize_kws_for_ctx(test: test, **options),
            **normalize_kws_for_model_assertion(test: test, **options),
          }

          return kws
        end

        # @semi-public used in rspec-trailblazer.
        # Used when building the incoming {ctx}, e.g. in {#run}.
        def normalize_kws_for_ctx(test:, key_in_params: test.key_in_params, default_ctx: test.default_ctx, **)
          {
            default_ctx:          default_ctx,
            key_in_params:        key_in_params,
          }
        end

        def normalize_kws_for_model_assertion(test:, expected_attributes: test.expected_attributes, model_at: :model, **)
          {
            expected_attributes:  expected_attributes,
            model_at:             model_at,
          }
        end

        # FIXME: when {deep_merge: true} the result hash contains subclassed AR classes instead of the original ones.
        #        when we got this sorted we can allows deep merging here, too.
        # @semi-public (for rspec-trailblazer).
        def expected_attributes_for(expected_attributes_to_merge, expected_attributes:, deep_merge: false, **)
          _expected_attributes = Suite.merge_for(expected_attributes, expected_attributes_to_merge, deep_merge)
        end
      end
    end
  end
end
