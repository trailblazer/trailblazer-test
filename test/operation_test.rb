require "test_helper"

class OperationTest < Minitest::Spec
  class Result
    def initialize(success, model)
      @success = success
      @model = model
    end

    def success?
      @success
    end

    def [](name)
      @model
    end
  end

  class Create
    def self.call(params)
      if params[:band] == "Rancid"
        model = Struct.new(:title, :band).new(params[:title].strip, params[:band])
        Result.new(true, model)
      end
    end
  end

  include Trailblazer::Test::Assertions
  include Trailblazer::Test::Operation::Assertions


  let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }

  #:exp-eq
  it do
    exp = assert_raises do
      input_params = { title: "Timebomb", band: "Rancid" }

      assert_pass Create, input_params, input_params
    end

    exp.inspect.must_match %{NameError: undefined local variable or method `params_pass'}
  end
  #:exp-eq end

  #-
  # params is sub-set, expected is sub-set and both get merged with *_valid.
  describe "Create with sane data" do
    let(:params_pass) { { band: "Rancid" } }
    let(:attrs_pass)  { { band: "Rancid", title: "Timebomb" } }

    it { assert_pass Create, { title: "  Ruby Soho " }, { title: "Ruby Soho" } }
  end

end
