require "test_helper"

# Document {Assertion#asserr_pass} and friends.
class DocsAssertionTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self)

  class Memo < Struct.new(:id, :title, :content, :persisted?, :errors)
    def save
      self[:persisted?] = true
      self[:id] = 1
    end

    module Operation
      class Create < Trailblazer::Operation
        class Form < Reform::Form
          require "reform/form/dry"
          include Reform::Form::Dry

          property :title
          property :content

          validation do
           params do
              required(:title).filled
              required(:content).filled(min_size?: 8)
            end
          end
        end

        step Model::Build(Memo, :new)
        step Contract::Build(constant: Form)
        step Contract::Validate(key: :memo)
        step Contract::Persist()
      end
    end
  end

  it "just check if operation passes" do
    assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}}
  end

  it "passes with correct params" do
    assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}},
      title:      "Todo",
      persisted?: true,
      id:         ->(asserted:, **) { asserted.id > 0 } # dynamic assertion.
  end

  it "returns result" do
    result = assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}} #, {title: "Todo"}

    assert_equal result[:model].title, "Todo"
  end

  it "block syntax" do
    assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}} do |result|
      assert_equal result[:model].title, "Todo"
    end

    # Note that you may combine attrs and block syntax.
  end

  class ModelAtTest < Minitest::Spec
    Trailblazer::Test::Assertion.module!(self)

    module Memo
      module Operation
        class Create < Trailblazer::Operation
          step ->(ctx, **) { ctx[:record] = DocsAssertionTest::Memo.new(1, "Todo") }
        end
      end
    end

    it "{:model_at}" do
      assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}}, model_at: :record,
        title:      "Todo"
    end
  end

  it "{#assert_fail} simply fails" do
    assert_fail Memo::Operation::Create, {params: {memo: {}}}
  end

  it "{#assert_fail} with contract errors, short-form" do
    assert_fail Memo::Operation::Create, {params: {memo: {}}}, [:title, :content]
  end

  it "{#assert_fail} with contract errors, with error messages" do
    assert_fail Memo::Operation::Create, {params: {memo: {}}},
      # error messages from contract:
      {
        title: ["must be filled"],
        content: ["must be filled", "size cannot be less than 8"]
      }
  end

  it "{#assert_fail} returns result" do
    result = assert_fail Memo::Operation::Create, {params: {memo: {}}}#, [:title, :content]
    assert_equal result[:"contract.default"].errors.size, 2
  end

  it "{#assert_fail} block form" do
    assert_fail Memo::Operation::Create, {params: {memo: {}}} do |result|
      assert_equal result[:"contract.default"].errors.size, 2
    end
  end

  # mock_step
  class MockStepTest < Minitest::Spec
    Trailblazer::Test::Assertion.module!(self)
    include Trailblazer::Test::Helper::MockStep # FIXME.

    Memo = Class.new(DocsAssertionTest::Memo)

    module Memo::Operation
      class Validate < Trailblazer::Operation
        step :check_params
        step :verify_content

        include Testing.def_steps(:check_params, :verify_content)
      end

      class Create < Trailblazer::Operation
        step :model
        step Subprocess(Validate)
        step :save

        include Testing.def_steps(:model, :save)
      end
    end

    it "allows mocking steps on first level" do
      create_operation = mock_step(Memo::Operation::Create, path: [:save]) do |ctx, **|
        # new logic for {save}.
        ctx[:saved] = true
      end

      result = create_operation.(seq: [])
      assert_equal result[:seq].inspect, %([:model, :check_params, :verify_content])
      assert_equal result[:saved], true

      result =
      assert_pass create_operation, {
        #~skip
        seq: []
        #~skip end
      }

      assert_equal result[:saved], true
    end

  end
  # run (???)
end
