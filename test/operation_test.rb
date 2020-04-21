require "test_helper"

class OperationTest < Minitest::Spec
  include Trailblazer::Test::Assertions
  include Trailblazer::Test::Operation::Assertions

  let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }
  let(:user)    { Struct.new(:name).new("allowed") }
  let(:default_options) { {current_user: user} }

  #:exp-eq
  it do
    exp = assert_raises do
      input_params = {title: "Timebomb", band: "Rancid"}

      assert_pass Update, input_params, input_params
    end

    exp.inspect.include? %(NameError: undefined method `default_params')
  end
  #:exp-eq end

  describe "Passing the wrong expected_attrs type" do
    it "raises a ExpectedErrorsTypeError" do
      exp = assert_raises do
        assert_fail Update, ctx(band: "Something"), "band"
      end

      exp.inspect.include? %(ExpectedErrorsTypeError: expected_errors has to be an Array)
    end
  end

  describe "with different contract name" do
    let(:default_params) { {band: "Rancid"} }

    it "assert a different contract" do
      assert_fail CustomUpdate, ctx(band: "Adolescents"), expected_errors: [:band], contract_name: "custom"
    end
  end

  describe "With nested params" do
    let(:default_params) { {form: {band: "Rancid"}} }
    let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

    it { assert_pass CreateNestedParams, params(form: {title: "Ruby Soho"}), title: "Ruby Soho" }
    it { assert_fail CreateNestedParams, params(form: {band: nil}), expected_errors: [:band] }
    it { assert_fail CreateNestedParams, params(form: {band: "NOFX"}, deep_merge: false), expected_errors: [:band] }

    it "raise an error because params[:form] is nil" do
      exp = assert_raises do
        assert_fail CreateNestedParams, params(band: "NOFX", deep_merge: false), expected_errors: [:band]
      end

      exp.inspect.must_match %(NoMethodError: undefined method `strip' for nil:NilClass)
    end
  end
end
