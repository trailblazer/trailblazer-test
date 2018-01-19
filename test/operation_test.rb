require "test_helper"

class OperationTest < Minitest::Spec
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
      return @model if name == "model"
      return @errors if name == "contract.default"
    end
  end

  Errors = Struct.new(:messages) do
    def errors
      self
    end
  end

  class Create
    def self.call(params)
      if params[:band] == "Rancid"
        model = Struct.new(:title, :band).new(params[:title].strip, params[:band])
        Result.new(true, model, nil)
      else

        Result.new( false, nil, Errors.new({band: ["must be Rancid"] }) )
      end
    end
  end

  include Trailblazer::Test::Assertions
  include Trailblazer::Test::Operation::Assertions


  let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }

  #-
  # params is sub-set, expected is sub-set and both get merged with *_valid.
    #- simple: actual input vs. expected
  #:pass
  describe "Create with sane data" do
    let(:params) { { band: "Rancid", title: "Ruby Soho" } }
    let(:default_params) { { band: "Rancid" } }

    # just works
    it { assert_pass Create, params, params }
    # trimming works
    it { assert_pass Create, { title: "  Ruby Soho " }, params, default_params: default_params }
  end
  #:pass end

  #:pass-block
  describe "Create with sane data" do
    let(:params) { { band: "Rancid", title: "Ruby Soho" } }

    it do
      assert_pass Create, params, {} do |result|
        assert_equal "Ruby Soho", result["model"].title
      end
    end
  end
  #:pass-block end

    #- simple: actual input vs. expected
  #:fail
  describe "Create with invalid data" do
    let(:params) { { band: "Adolescents" } }

    it { assert_fail Create, params, [:band] }
  end
  #:fail end

    #- with block
  #:fail-block
  describe "Create with invalid data" do
    it do
      assert_fail Create, { band: " Adolescents" }, {} do |result|
        assert_equal( {:band=>["must be Rancid"]}, result["contract.default"].errors.messages )
      end
    end
  end
  #:fail-block end
end
