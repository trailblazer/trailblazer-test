# module MiniTest::Assertions
module Trailblazer
  module Test
    # Evaluate value if it's a lambda, and let the caller know whether we need an
    # assert_equal or an assert.
    def self.expected(asserted, value, actual)
      value.is_a?(Proc) ? [value.(actual: actual, asserted: asserted), false] : [value, true]
    end

    # Read the actual value from the asserted object (e.g. a model).
    def self.actual(asserted, reader, name)
      reader ? asserted.public_send(reader, name) : asserted.public_send(name)
    end

    module Assertions
      include Assertion::AssertExposes
    end
  end
end
# Trailblazer::Operation::Result.infect_an_assertion :assert_result_matches, :must_match, :do_not_flip
# Object.infect_an_assertion :assert_exposes, :must_expose, :do_not_flip
