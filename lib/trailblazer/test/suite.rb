module Trailblazer
  module Test
    # Offers the assertions `#assert_pass` and friends but with a configuration "DSL".
    # That means you can write super short and concise test cases using the defaulting
    # in this module.
    module Suite
      # Defaults so tests run without tweaking (almost).
      module Spec
        def self.included(includer)
          includer.let(:operation)            { raise "Trailblazer::Test: `let(:operation) { ... }` is missing" }
          includer.let(:key_in_params)        { false }
          includer.let(:expected_attributes)  { {} } # You need to override this in your tests.
          includer.let(:default_ctx)          { {} }
        end
      end

      # For Minitest::Test, given there are still people using this awkward syntax. :)
      module Test
        def operation
          raise "Trailblazer::Test: `def operation` is missing"
        end

        def key_in_params
          false
        end

        def expected_attributes
          {}
        end

        def default_ctx
          {}
        end
      end

      # The assertions and helpers included into the actual test.
      def assert_pass(params_fragment, expected_attributes_to_merge={}, assertion: Assertion::AssertPass, **kws, &block)
        Assert.assert_pass(params_fragment, test: self, user_block: block, assertion: assertion, expected_attributes_to_merge: expected_attributes_to_merge, **kws)
      end

      def assert_fail(params_fragment, expected_errors=nil, assertion: Assertion::AssertFail, **kws, &block)
        Assert.assert_fail(params_fragment, expected_errors, test: self, user_block: block, assertion: assertion, **kws)
      end

      def assert_pass?(*args, **kws, &block)
        assert_pass(*args, **kws, invoke: Assertion.method(:invoke_operation_with_wtf), &block)
      end

      def assert_fail?(*args, **kws, &block)
        assert_fail(*args, **kws, invoke: Assertion.method(:invoke_operation_with_wtf), &block)
      end

      def Ctx(*args, **kws)
        Assert.Ctx(*args, test: self, **kws)
      end
    end # Suite
  end
end
