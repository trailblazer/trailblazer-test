require "hashie"
require "trailblazer/test/context"

module Trailblazer
  module Test
    module Assertion
      # Offers the assertions `#assert_pass` and friends but with a configuration "DSL".
      # That means you can write super short and concise test cases using the defaulting
      # in this module.
      module Suite
        # Defaults so tests run without tweaking (almost).
        def self.included(includer)
          includer.let(:operation)            { raise "Trailblazer::Test: `let(:operation) { ... }` is missing" }
          includer.let(:key_in_params)        { false }
          includer.let(:expected_attributes)  { {} } # You need to override this in your tests.
          includer.let(:default_ctx)          { {} }

          include AssertExposes
        end

        def assert_pass(params_fragment, expected_attributes_to_merge, use_wtf=false, deep_merge: true, assertion: AssertPass, **kws, &block)
          Assert.assert_pass(params_fragment, expected_attributes_to_merge, use_wtf, test: self, user_block: block, assertion: assertion, **kws)
        end

        def assert_fail(params_fragment, expected_errors, use_wtf=false, deep_merge: true, assertion: AssertFail, **kws, &block)
          Assert.assert_fail(params_fragment, expected_errors, use_wtf, test: self, user_block: block, assertion: assertion, **kws)
        end

        def Ctx(*args, **kws)
          Assert.Ctx(*args, test: self, **kws)
        end


        # Provide {Assert.assert_pass} which decouples the assertion logic from the actual test framework.
        module Assert
          module_function

          def normalize_for(params_fragment, use_wtf, **kws)
            kws = normalize_kws(use_wtf, **kws)
            ctx = ctx_for_params_fragment(params_fragment, **kws)

            return ctx, kws
          end

          #@public
          def assert_pass(params_fragment, expected_attributes_to_merge, use_wtf=false, deep_merge: true, assertion:, test:, user_block:, **kws)
            ctx, kws = normalize_for(params_fragment, use_wtf, test: test, user_block: user_block, **kws)

            expected_attributes = expected_attributes_for(expected_attributes_to_merge, **kws)

            activity = kws[:operation]  # FIXME.
            model_at = kws[:model_at]  # FIXME.

            assertion.(activity, ctx, use_wtf: use_wtf, test: test, model_at: model_at, user_block: user_block, **expected_attributes)
          end

          def assert_fail(params_fragment, expected_errors, use_wtf=false, assertion:, **kws)
            ctx, kws = normalize_for(params_fragment, use_wtf, **kws)

            activity = kws[:operation]  # FIXME.

            assertion.(activity, ctx, expected_errors, **kws)
          end

          #@private
          def ctx_for_params_fragment(params_fragment, key_in_params:, default_ctx:, **)
            return params_fragment if params_fragment.kind_of?(Trailblazer::Test::Context)
            # If {:key_in_params} is given, key the {params_fragment} with it, e.g. {params: {transaction: {.. params_fragment ..}}}
            merge_with_ctx = key_in_params ? {params: {key_in_params => params_fragment}} : {params: params_fragment}

            ctx = merge_for(default_ctx, merge_with_ctx, true)
          end

          # @private
          # Gather all test case configuration. This involves reading all test `let` directives.
          def normalize_kws(use_wtf, user_block:, test:, operation: test.operation, expected_attributes: test.expected_attributes, contract_name: "default", model_at: :model, **options)
            kws = {
              user_block:           user_block,
              operation:            operation,
              expected_attributes:  expected_attributes,
              test:                 test,
              contract_name:        contract_name,
              model_at:             model_at,

              **normalize_kws_for_ctx(test: test, **options)
            }

            kws[:invoke_method] = :wtf? if use_wtf

            return kws
          end

          def normalize_kws_for_ctx(test:, key_in_params: test.key_in_params, default_ctx: test.default_ctx)
            {
              default_ctx:          default_ctx,
              key_in_params:        key_in_params,
            }
          end

          # FIXME: when {deep_merge: true} the result hash contains subclassed AR classes instead of the original ones.
          #        when we got this sorted we can allows deep merging here, too.
          def expected_attributes_for(expected_attributes_to_merge, expected_attributes:, deep_merge: false, **)
            _expected_attributes = merge_for(expected_attributes, expected_attributes_to_merge, deep_merge)
          end

          # @private
          class CtxHash < Hash
            include Hashie::Extensions::DeepMerge
          end

          # @private
          def merge_for(dest, source, deep_merge)
            return dest.merge(source) unless deep_merge

            CtxHash[dest].deep_merge(CtxHash[source]) # FIXME: this subclasses ActiveRecord classes in dest like {class: ReportSubscription}
          end

          def Ctx(merge_with_ctx={}, exclude: false, merge: true, **kws)
            if merge
              options       = normalize_kws_for_ctx(**kws)
              key_in_params = options[:key_in_params]
              default_ctx   = options[:default_ctx]

              # Extract {:params} from {default_ctx}
              default_params = key_in_params ? default_ctx[:params][key_in_params] : default_ctx[:params]

              # Remove {:exclude} variables from the {params:} part
              filtered_default_params =
                if exclude
                  default_params.slice(*(default_params.keys - exclude))
                else
                  default_params # use original params if no filtering configured.
                end

              # FIXME: very, very redundant.
              default_params_for_ctx = key_in_params ? {key_in_params => filtered_default_params} : filtered_default_params

              ctx = default_ctx.merge({params: default_params_for_ctx})
            else # FIXME: if/else here sucks.
              ctx = {}
            end

            ctx = Assert.merge_for(ctx, merge_with_ctx, true) # merge injections

            Trailblazer::Test::Context[ctx] # this signals "pass-through"
          end
        end # Assert
      end # Suite
    end
  end
end
