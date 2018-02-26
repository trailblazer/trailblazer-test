require "test_helper"
require "trailblazer/test/deprecation/assertions"

class DeprecationTest < Minitest::Spec
  class Result < Result
    def [](name)
      return @model if name == "model"
      return @errors if name == "contract.default"
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

  include Trailblazer::Test::Deprecation::Assertions

  let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }

  describe "Create with sane data" do
    let(:params_pass) { { band: "Rancid" } }
    let(:attrs_pass)  { { band: "Rancid", title: "Timebomb" } }

    it { assert_pass Create, { title: "Ruby Soho" }, { title: "Ruby Soho" } }
  end

  describe "Create with sane data and block" do
    let(:params_pass) { { band: "Rancid" } }
    let(:attrs_pass)  { { band: "Rancid", title: "Timebomb" } }

    it do
      assert_pass Create, { title: " Ruby Soho" }, {} do |result|
        assert_equal "Ruby Soho", result["model"].title
      end
    end
  end
end
