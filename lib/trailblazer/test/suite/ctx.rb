require "hashie"
require "trailblazer/test/context"

module Trailblazer
  module Test
    module Suite
      # @private
      class CtxHash < Hash
        include Hashie::Extensions::DeepMerge
      end

      module_function
      # @private
      def merge_for(dest, source, deep_merge)
        return dest.merge(source) unless deep_merge

        CtxHash[dest].deep_merge(CtxHash[source]) # FIXME: this subclasses ActiveRecord classes in dest like {class: ReportSubscription}
      end

      def Ctx(merge_with_ctx={}, exclude: false, merge: true, **kws)
        if merge
          options       = Suite::Assert.normalize_kws_for_ctx(test: self, **kws) # FIXME: why test?
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

        ctx = Suite.merge_for(ctx, merge_with_ctx, true) # merge injections

        Trailblazer::Test::Context[ctx] # this signals "pass-through"
      end
    end # Suite
  end
end
