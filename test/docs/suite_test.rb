require "test_helper"
#:operation-spec
# test/test_helper.rb
# ...

class OperationSpec < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self, suite: true)
end
#:operation-spec end

# {Memo}, {Memo::Operation::Create} etc is from lib/trailblazer/test/testing.rb.
class DocsSuiteAssertionsTest < Minitest::Spec
  Memo = Trailblazer::Test::Testing::Memo
  Trailblazer::Test::Assertion.module!(self, suite: true)

  Memo::Operation::Update = Class.new(Memo::Operation::Create)

  #:test
  #:install
  class MemoOperationTest < Minitest::Spec  # test/memo/operation_test.rb
    #~zoom
    Trailblazer::Test::Assertion.module!(self, suite: true)
  #:install end

    # The default ctx passed into the tested operation.
    #:default-ctx
    let(:default_ctx) do
      {
        params: {
          memo: { # Note the {:memo} key here!
            title:   "Todo",
            content: "Stock up beer",
          }
        }
      }
    end
    #:default-ctx end

    #:expected-attrs
    # What will the model look like after running the operation?
    let(:expected_attributes) do
      {
        title:   "Todo",
        content:  "Stock up beer",
      }
    end
    #:expected-attrs end

    #:let-operation
    let(:operation)     { Memo::Operation::Create }
    #:let-operation end
    #:let-key-in-params
    let(:key_in_params) { :memo }
    #:let-key-in-params end

    #:assert-pass
    it "accepts {tag_list} and converts it to an array" do
      assert_pass(
        {tag_list: "fridge,todo"}, # input + default_ctx
        {tag_list: ["fridge", "todo"]}) # what's expected on the model.
    end
    #:assert-pass end
    #~zoom end

    #:assert-pass-empty
    it "passes with valid input, {tag_list} is optional" do
      assert_pass( {}, {} )
    end
    #:assert-pass-empty end

    #:assert-pass-block
    it "converts {tag_list} and converts it to an array" do
      assert_pass( {tag_list: "fridge,todo"}, {tag_list: ["fridge", "todo"]} ) do |result|
        assert_equal true, result[:model].persisted?
      end
    end
    #:assert-pass-block end

    #:assert-fail
    it "fails with invalid {tag_list}" do
      assert_fail({tag_list: []}, [:tag_list])
    end
    #:assert-fail end

    #:option-operation
    it "Update allows integer {duration}" do
      assert_pass({tag_list: "todo"}, {tag_list: ["todo"]}, operation: Memo::Operation::Update )
    end
    #:option-operation end

    let(:yogi) { "Yogi" }

    #:ctx-example
    it "fails with missing key {:title}" do
      assert_fail( Ctx(exclude: [:title]), [:title] ) do |result|
        assert_equal ["must be filled"], result[:"contract.default"].errors[:title]
      end
    end
    #:ctx-example end

    #:ctx-pass
    it "passes" do
      assert_pass( Ctx({current_user: yogi}), {} )
    end
    #:ctx-pass end

    #:ctx-inject
    it "passes with correct {current_user}" do
      ctx = Ctx({current_user: yogi}  )
      puts ctx
      #=> {:params=>{:memo=>{:title=>"Todo", :content=>"Stock up beer"}},
      #    :current_user=>"Yogi"}

      assert_pass ctx, {}
      #~skip
      assert_equal CU.inspect(ctx), %({:params=>{:memo=>{:title=>\"Todo\", :content=>\"Stock up beer\"}}, :current_user=>\"Yogi\"})
      #~skip end
    end
    #:ctx-inject end

    # allows deep-merging additionnal {:params}
    #:ctx-merge
    it "passes with correct tag_list for user" do
      ctx = Ctx(
        {
          current_user: yogi,
          # this is deep-merged with default_ctx!
          params: {memo: {title: "Reminder"}}
        }
      )

      assert_pass ctx, {title: "Reminder"}
    #:ctx-merge end
=begin
          #:ctx-merge-actual
          {:params=>{
            :memo=>{
              :title=>"Reminder",
              :content=>"Stock up beer"
             }
            },
          :current_user=>"Yogi"}
          #:ctx-merge-actual end
=end
      #~skip
      assert_equal CU.inspect(ctx), %({:params=>{:memo=>{:title=>\"Reminder\", :content=>\"Stock up beer\"}}, :current_user=>\"Yogi\"})

      #~skip end
    end

    #:ctx-exclude
    it "provides {Ctx()}" do
      ctx = Ctx(exclude: [:title])
      #=> {:params=>{:memo=>{:content=>"Stock up beer"}}}

      assert_fail ctx, [:title]
      #~skip
      assert_equal CU.inspect(ctx), %{{:params=>{:memo=>{:content=>\"Stock up beer\"}}}}
      #~skip end
    end
    #:ctx-exclude end

    it "allows {:exclude} and merge into {params}" do
      #:ctx-exclude-params-merge
      ctx = Ctx({params: {memo: {tag_list: "todo"}}}, exclude: [:title])
      #=> {:params=>{:memo=>{:content=>"Stock up beer", :tag_list=>"todo"}}}
      #:ctx-exclude-params-merge end

      assert_equal CU.inspect(ctx), %({:params=>{:memo=>{:content=>"Stock up beer", :tag_list=>"todo"}}})
    end

    #:ctx-exclude-merge
    it "provides {Ctx()}" do
      ctx = Ctx({current_user: yogi}, exclude: [:title])
      #=> {:params=>{:memo=>{:content=>"Stock up beer"}},
      #    :current_user=>#<User name="Yogi">}
      #~skip
      assert_equal CU.inspect(ctx), %({:params=>{:memo=>{:content=>\"Stock up beer\"}}, :current_user=>\"Yogi\"})
      #~skip end
    end
    #:ctx-exclude-merge end

    it "{Ctx} provides {merge: false} to allow direct ctx building without any automatic merging" do
      ctx = Ctx({current_user: yogi}, merge: false)

      assert_equal CU.inspect(ctx), %({:current_user=>\"Yogi\"})
    end

    #~meths end
  end
  #:test end

  # No {key: :song}.
  class SongOperation_OMIT_KEY_Test < OperationSpec
    module Memo; end

    module Memo::Operation
      class Create < Trailblazer::Operation
        step Model(DocsSuiteAssertionsTest::Memo, :new)
        step Contract::Build(constant: DocsSuiteAssertionsTest::Memo::Operation::Create::Form)
        step Contract::Validate()
        step Contract::Persist()
      end
    end
    let(:operation) { Memo::Operation::Create }
    #:key_in_params
    let(:key_in_params) { false }
    #:key_in_params end

    # What will the model look like after running the operation?
    let(:expected_attributes) do
      {
        title:   "Todo",
        content:  "Stock up beer",
      }
    end

    #:let-key-in-params-false
    let(:default_ctx) do
      {
        params: {
          title:   "Todo",
          content: "Stock up beer",
        }
      }
    end
    #:let-key-in-params-false end

    it "passes with valid input, {duration} is optional" do
      assert_pass( {}, {} )
    end

    #:omit-key-it
    it "sets {title}" do
      assert_pass( {title: "Remember"}, {title: "Remember"} )
    end
    #:omit-key-it end

    it "fails with missing {title} and invalid {duration}" do
      assert_fail( {title: ""}, [:title] )
    end

    it "Ctx()" do
      assert_equal CU.inspect(Ctx(exclude: [:title])), %({:params=>{:content=>\"Stock up beer\"}})
      assert_equal CU.inspect(Ctx({current_user: Module}, exclude: [:title])), %({:params=>{:content=>\"Stock up beer\"}, :current_user=>Module})
      assert_equal CU.inspect(Ctx({current_user: Module, params: {duration: 999}}, exclude: [:title])), %({:params=>{:content=>\"Stock up beer\", :duration=>999}, :current_user=>Module})
    end
  end # SongOperation_OMIT_KEY_Test
end

  # include Trailblazer::Test::Operation::PolicyAssertions

  # #:policy_fail-block
  # describe "Update with failing policy" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

  #   it do
  #     assert_policy_fail Update, Ctx({title: "Ruby Soho"}, current_user: not_allowed_user)
  #   end
  # end
  # #:policy_fail-block end

  # describe "Update failing with custom policy" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

  #   it do
  #     #:policy_fail-custom-name
  #     assert_policy_fail CustomUpdate, Ctx({title: "Ruby Soho"}, current_user: not_allowed_user), policy_name: "custom"
  #     #:policy_fail-custom-name end
  #   end
  # end

# Test that the Suite module also works with a Minitest::Test class.
#:test-suite
class MemoCreateTest < Minitest::Test
  Trailblazer::Test::Assertion.module!(self, suite: true, spec: false)
  #~skip
  Memo = Trailblazer::Test::Testing::Memo
  #~skip end
  def operation; Memo::Operation::Create end
  def default_ctx; {params: {memo: {title: "Note to self", content: "Remember me!"}}} end
  def expected_attributes; {title: "Note to self", content: "Remember me!"} end
  def key_in_params; :memo end

  def test_our_assertions
    assert_pass({}, {})
  end
end
#:test-suite end
