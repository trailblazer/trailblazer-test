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
    def self.call(params, context)
      if params[:band] == "Rancid" && context['current_user'].name == 'allowed'
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
  let(:user) { Struct.new(:name).new("allowed") }
  let(:context) { { 'current_user' => user } }

  #:exp-eq
  it do
    exp = assert_raises do
      input_params = { title: "Timebomb", band: "Rancid" }

      assert_pass Create, input_params, input_params, context: context
    end

    exp.inspect.must_match %{NameError: undefined local variable or method `params_pass'}
  end
  #:exp-eq end

  #-
  # params is sub-set, expected is sub-set and both get merged with *_valid.
    #- simple: actual input vs. expected
  #:pass
  describe "Create with sane data" do
    let(:params_pass) { { band: "Rancid" } }
    let(:attrs_pass)  { { band: "Rancid", title: "Timebomb" } }

    # just works
    it { assert_pass Create, { title: "Ruby Soho" }, { title: "Ruby Soho" }, context: context }
    # trimming works
    it { assert_pass Create, { title: "  Ruby Soho " }, { title: "Ruby Soho" }, context: context }
  end
  #:pass end

  #:pass-block
  describe "Create with sane data" do
    let(:params_pass) { { band: "Rancid" } }
    let(:attrs_pass)  { { band: "Rancid", title: "Timebomb" } }

    it do
      assert_pass Create, { title: " Ruby Soho" }, {}, context: context do |result|
        assert_equal "Ruby Soho", result["model"].title
      end
    end
  end
  #:pass-block end

    #- simple: actual input vs. expected
  #:fail
  describe "Create with invalid data" do
    let(:params_pass) { { band: "Rancid" } }

    it { assert_fail Create, { band: "Adolescents" }, expected_errors: [:band] }
  end
  #:fail end

  #:fail-not-allowed-user
  describe "Create with invalid user" do
    let(:params_pass) { { band: "Rancid" } }
    let(:attrs_pass)  { { band: "Rancid", title: "Timebomb" } }
    let(:user) { Struct.new(:name).new('not_allowed') }

    it { assert_fail Create, { title: "Ruby Soho" }, context: context }
  end
  #:fail-not-allowed-user end

    #- with block
  #:fail-block
  describe "Create with invalid data" do
    let(:params_pass) { { band: "Rancid" } }

    it do
      assert_fail Create, { band: " Adolescents" }, context: context do |result|
        assert_equal( {:band=>["must be Rancid"]}, result["contract.default"].errors.messages )
      end
    end
  end
  #:fail-block end
end
