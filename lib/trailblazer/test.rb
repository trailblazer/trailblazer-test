require "trailblazer/test/version"

module Trailblazer
  module Test
    # Your code goes here...

    def self.module!(*args, **options, &block)
      Assertion.module!(*args, **options, &block)
    end
  end
end

require "trailblazer/test/assertion/assert_exposes"
require "trailblazer/test/assertion/assert_pass"
require "trailblazer/test/assertion/assert_fail"
require "trailblazer/test/assertion"
require "trailblazer/test/suite"
require "trailblazer/test/suite/assert"
require "trailblazer/test/suite/ctx"
require "trailblazer/test/helper/mock_step"
# require "trailblazer/test/operation/policy_assertions"
