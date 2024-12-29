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

  it "what" do
    assert_pass Memo::Operation::Create, {params: {memo: {title: "Todo", content: "Buy beer"}}},
      title: "Todo",
      persisted?: true,
      id: ->(asserted:, **) { asserted.id > 0 }
  end
end
