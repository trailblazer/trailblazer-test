module Trailblazer
  module Test
    # DISCUSS: this is not really endpoint related, it's more like setting a "global" invocation mechanism.
    module Endpoint
      # DISCUSS: not sure this is the final "technique" to use the global endpoint invoker.
      def self.module!(receiver, invoke_method:, invoke_method_wtf:)
        receiver.class_eval do
          @@INVOKE_METHOD = invoke_method
          @@INVOKE_METHOD_WTF = invoke_method_wtf

          def trailblazer_test_invoke_method
            @@INVOKE_METHOD
          end

          def trailblazer_test_invoke_method_wtf
            @@INVOKE_METHOD_WTF
          end
        end

        Assertion
      end

      module Assertion
        def assert_pass(*args, invoke: trailblazer_test_invoke_method, **options, &block)
          super(*args, **options, invoke: invoke, &block)
        end

        def assert_fail(*args, invoke: trailblazer_test_invoke_method, **options, &block)
          super(*args, **options, invoke: invoke, &block)
        end

        def assert_pass?(*args, **options, &block)
          assert_pass(*args, **options, invoke: trailblazer_test_invoke_method_wtf, &block)
        end

        def assert_fail?(*args, **options, &block)
          assert_fail(*args, **options, invoke: trailblazer_test_invoke_method_wtf, &block)
        end
      end
    end
  end
end
