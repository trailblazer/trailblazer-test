require "test_helper"

class DocsPassFailAssertionsTest < Minitest::Spec
  include Trailblazer::Test::Assertions
  include Trailblazer::Test::Operation::Assertions

  let(:user)    { Struct.new(:name).new("allowed") }
  let(:default_options) { {current_user: user} }

  #-
  # params is sub-set, expected is sub-set and both get merged with *_valid.
  #- simple: actual input vs. expected

  #:assert_pass
  describe "Create with sane data" do
    let(:default_params) { {band: "Rancid"} }
    let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

    # just works
    it { assert_pass Create, params(title: "Ruby Soho"), title: "Ruby Soho" }
    # trimming works
    it { assert_pass Create, params(title: "  Ruby Soho "), title: "Ruby Soho" }
  end
  #:assert_pass end

  #:assert_pass-with-ctx
  describe "Update with sane data" do
    let(:default_params) { {band: "Rancid"} }
    let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

    # just works
    it { assert_pass Update, ctx(title: "Ruby Soho"), title: "Ruby Soho" }
    # trimming works
    it { assert_pass Update, ctx(title: "  Ruby Soho "), title: "Ruby Soho" }
  end
  #:assert_pass-with-ctx end
 
  #:assert_pass-block
  describe "Update with sane data" do
    let(:default_params) { {band: "Rancid"} }
    let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

    it do
      assert_pass Update, ctx(title: " Ruby Soho"), {} do |result|
        assert_equal "Ruby Soho", result[:model].title
      end
    end
  end
  #:assert_pass-block end

  #:assert_fail
  describe "Update with invalid data" do
    let(:default_params) { {band: "Rancid"} }

    it { assert_fail Update, ctx(band: "Adolescents"), expected_errors: [:band] }
  end
  #:assert_fail end

  #:assert_fail-block
  describe "Update with invalid data" do
    let(:default_params) { {band: "Rancid"} }

    it do
      assert_fail Update, ctx(band: " Adolescents") do |result|
        assert_equal({band: ["must be Rancid"]}, result["contract.default"].errors.messages)
      end
    end
  end
  #:assert_fail-block end

  include Trailblazer::Test::Operation::PolicyAssertions

  #:policy_fail-block
  describe "Update with failing policy" do
    let(:default_params) { {band: "Rancid"} }
    let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

    it do
      assert_policy_fail Update, ctx({title: "Ruby Soho"}, current_user: not_allowed_user)
    end
  end
  #:policy_fail-block end

  describe "Update failing with custom policy" do
    let(:default_params) { {band: "Rancid"} }
    let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

    it do
      #:policy_fail-custom-name
      assert_policy_fail CustomUpdate, ctx({title: "Ruby Soho"}, current_user: not_allowed_user), policy_name: "custom"
      #:policy_fail-custom-name end
    end
  end
end
