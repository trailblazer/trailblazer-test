require "test_helper"
require "trailblazer/test/deprecation/operation/assertions"

class DeprecationTest < Minitest::Spec
  class Result < Result
    def [](name)
      return @model if name == "model"
      return @errors if name == "contract.default"
      return @errors.policy if name == "result.policy.default"
    end
  end

  class Create
    def self.call(params, _options)
      if params[:band] == "Rancid"
        model = Struct.new(:title, :band).new(params[:title].strip, params[:band])
        Result.new(true, model, nil)
      else

        Result.new(false, nil, Errors.new(band: ["must be Rancid"]))
      end
    end
  end

  class Update
    def self.call(params, options)
      return Result.new(false, nil, Errors.new(nil, Policy.new(false))) if options["current_user"].name != "allowed"

      if params[:band] == "Rancid"
        model = Struct.new(:title, :band).new(params[:title].strip, params[:band])
        Result.new(true, model, nil)
      else
        Result.new(false, nil, Errors.new(band: ["must be Rancid"]))
      end
    end
  end

  include Trailblazer::Test::Deprecation::Operation::Assertions

  let(:model)        { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }
  let(:user)         { Struct.new(:name).new("allowed") }
  let(:default_options) { {"current_user" => user} }

  describe "Create with sane data" do
    let(:default_params) { {band: "Rancid"} }
    let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

    it { assert_pass Create, params(title: "Ruby Soho"), title: "Ruby Soho" }
    it { assert_pass Create, params(title: "  Ruby Soho "), title: "Ruby Soho" }
  end

  describe "Update with sane data" do
    let(:default_params) { {band: "Rancid"} }
    let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

    it { assert_pass Update, ctx(title: "Ruby Soho"), title: "Ruby Soho" }
  end

  describe "Update with sane data and block" do
    let(:default_params) { {band: "Rancid"} }
    let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

    it do
      assert_pass Update, ctx(title: " Ruby Soho"), {} do |result|
        assert_equal "Ruby Soho", result["model"].title
      end
    end
  end

  describe "Update with invalid data" do
    let(:default_params) { {band: "Rancid"} }

    it { assert_fail Update, ctx(band: "Adolescents"), [:band] }
  end

  include Trailblazer::Test::Operation::PolicyAssertions

  describe "Update with failing policy" do
    let(:default_params) { {band: "Rancid"} }

    it do
      assert_policy_fail Update, ctx({title: "Ruby Soho"}, "current_user" => Struct.new(:name).new("not_allowed"))
    end
  end
end
