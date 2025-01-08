require "test_helper"

# Document {Assertion#asserr_pass} and friends.
class DocsAssertionTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self)

  Memo = Trailblazer::Test::Testing::Memo

  #:pass-pass
  it "just check if operation passes" do
    input = {params: {memo: {title: "Todo", content: "Buy beer"}}}

    assert_pass Memo::Operation::Create, input
  end
  #:pass-pass end

  it "passes with correct params" do
    input = {params: {memo: {title: "Todo", content: "Buy beer"}}}
    #:pass-model
    assert_pass Memo::Operation::Create, input,
      title:      "Todo",
      persisted?: true,
      id:         ->(asserted:, **) { asserted.id > 0 } # dynamic test.
    #:pass-model end

=begin
    #:pass-model-manual
    assert_equal result[:model].title, "Todo"
    assert_equal result[:model].persisted?, true
    assert_equal result[:model].id > 0
    #:pass-model-manual end
=end
  end

  #:pass-return
  it "returns result" do
    #~skip
    input = {params: {memo: {title: "Todo", content: "Buy beer"}}} #, {title: "Todo"}
    #~skip end
    result = assert_pass Memo::Operation::Create, input

    assert_equal result[:model].title, "Todo" # your own assertion
  end
  #:pass-return end

  it "block syntax" do
    input = {params: {memo: {title: "Todo", content: "Buy beer"}}}
    #:pass-block
    assert_pass Memo::Operation::Create, input do |result|
      assert_equal result[:model].title, "Todo"
    end
    #:pass-block end

    # Note that you may combine attrs and block syntax.
  end

  it "wtf?" do
    input = {params: {memo: {title: "Todo", content: "Buy beer"}}}
    # out, _ = capture_io do
      #:pass-wtf
      assert_pass? Memo::Operation::Create, input
      #:pass-wtf end
    # end

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
      #:pass-model-at
      #~skip
      input = {params: {memo: {title: "Todo", content: "Buy beer"}}}
      #~skip end
      assert_pass Memo::Operation::Create, input, model_at: :record,
        title:      "Todo"
      #:pass-model-at end
    end
  end

  it "{#assert_fail} simply fails" do
    #:fail-basic
    assert_fail Memo::Operation::Create, {params: {memo: {}}}
    #:fail-basic end
  end

  it "{#assert_fail} with contract errors, short-form" do
    #:fail-array
    assert_fail Memo::Operation::Create, {params: {memo: {}}},
      [:title, :content] # fields with errors.
    #:fail-array end
  end

  it "{#assert_fail} with contract errors, with error messages" do
    #:fail-hash
    assert_fail Memo::Operation::Create, {params: {memo: {}}},
      # error messages from contract:
      {
        title: ["must be filled"],
        content: ["must be filled", "size cannot be less than 8"]
      }
    #:fail-hash end
  end

  it "{#assert_fail} returns result" do
    #:fail-return
    result = assert_fail Memo::Operation::Create, {params: {memo: {}}}#, [:title, :content]

    assert_equal result[:"contract.default"].errors.size, 2
    #:fail-return end
  end

  it "{#assert_fail} block form" do
    #:fail-block
    assert_fail Memo::Operation::Create, {params: {memo: {}}} do |result|
      assert_equal result[:"contract.default"].errors.size, 2
    end
    #:fail-block end
  end

  it "{#assert_fail} wtf?" do
    # out, _ = capture_io do
      #:fail-wtf
      assert_fail? Memo::Operation::Create, {params: {memo: {}}}
      #:fail-wtf end
    # end
  end

  # mock_step
  class MockStepTest < Minitest::Spec
    Trailblazer::Test::Assertion.module!(self)

    Memo = Class.new(DocsAssertionTest::Memo)

    module Memo::Operation
      class Validate < Trailblazer::Operation
        step :check_params
        step :verify_content

        include Testing.def_steps(:check_params, :verify_content)
      end

      class Create < Trailblazer::Operation
        step :model
        step Subprocess(Validate), id: :validate
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

    it "allows mocking steps any level" do
      create_operation = mock_step(Memo::Operation::Create, path: [:validate, :verify_content]) do |ctx, **|
        # new logic for {Validate#verify_content}.
        ctx[:is_verified] = true
      end

      result = create_operation.(seq: [])
      assert_equal result[:seq].inspect, %([:model, :check_params, :save])
      assert_equal result[:is_verified], true

      result =
      assert_pass create_operation, {
        #~skip
        seq: []
        #~skip end
      }

      assert_equal result[:is_verified], true
    end

  end
  # run (???)
end
