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
    end
  end

  Errors = Struct.new(:messages) do
    def errors
      self
    end
  end

end
