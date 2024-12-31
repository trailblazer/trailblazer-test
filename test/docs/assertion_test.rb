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
              required(:content).value(min_size?: 8)
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

  it "passes with correct params" do
    assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}},
      title:      "Todo",
      persisted?: true,
      id:         ->(asserted:, **) { asserted.id > 0 } # dynamic assertion.
  end

  it "returns result" do
    result = assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}}

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
end
