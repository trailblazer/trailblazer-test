$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "trailblazer/test"

require "minitest/autorun"

Minitest::Spec.class_eval do
  include Trailblazer::Test::Assertions
  include Trailblazer::Test::Operation::Assertions

  class Result
    def initialize(success, model, errors)
      @success = success
      @model = model
      @errors = errors
    end

    def success?
      @success
    end
    def failure?
      ! @success
    end

    def [](name)
      return @model if name == :model
      return @errors if name == "contract.default"
      return @errors.policy if name == "result.policy.default"
    end
  end

  Errors = Struct.new(:messages, :policy) do
    def errors
      self
    end
  end

  class Policy
    def initialize(success)
      @success = success
    end

    def success?
      @success
    end

    def failure?
      ! @success
    end
  end
end
