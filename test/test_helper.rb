require "bundler/setup"
require "simplecov"
SimpleCov.start do
  add_group "Trailblazer-Test", "lib"
  add_group "Tests", "test"
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
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

    attr_reader :errors

    def success?
      @success
    end

    def failure?
      !@success
    end

    def [](name)
      return @model if name == :model
      return @errors if name == "contract.default"
      return @errors.policy if name == "result.policy.default"
    end

    def wtf?
      puts "Operation trace"
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
      !@success
    end
  end

  class Create
    def self.call(params:)
      if params[:band] == "Rancid"
        model = Struct.new(:title, :band).new(params[:title].strip, params[:band])
        Result.new(true, model, nil)
      else

        Result.new(false, nil, Errors.new(band: ["must be Rancid"]))
      end
    end

    def self.trace(params:)
      call(params: params)
    end
  end

  class Update
    def self.call(params:, current_user:)
      return Result.new(false, nil, Errors.new(nil, Policy.new(false))) if current_user.name != "allowed"

      if params[:band] == "Rancid"
        model = Struct.new(:title, :band).new(params[:title].strip, params[:band])
        Result.new(true, model, nil)
      else

        Result.new(false, nil, Errors.new(band: ["must be Rancid"]))
      end
    end
  end

  class CreateNestedParams
    def self.call(params:)
      if params[:form][:band] == "Rancid"
        model = Struct.new(:title, :band).new(params[:form][:title].strip, params[:form][:band])
        Result.new(true, model, nil)
      else

        Result.new(false, nil, Errors.new(band: ["must be Rancid"]))
      end
    end
  end
end
