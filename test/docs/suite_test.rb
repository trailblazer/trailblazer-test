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
  Song = Trailblazer::Test::Testing::Song
  Trailblazer::Test::Assertion.module!(self, suite: true)

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
      assert_pass({tag_list: "fridge,todo"},
        {tag_list: ["fridge", "todo"]}) # what we're expecting on the model.
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
      assert_equal %({:params=>{:memo=>{:title=>\"Todo\", :content=>\"Stock up beer\"}}, :current_user=>\"Yogi\"}), ctx.inspect
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
      assert_equal ctx.inspect, %({:params=>{:memo=>{:title=>\"Reminder\", :content=>\"Stock up beer\"}}, :current_user=>\"Yogi\"})

      #~skip end
    end

    #:ctx-exclude
    it "provides {Ctx()}" do
      ctx = Ctx(exclude: [:title])
      #=> {:params=>{:memo=>{:content=>"Stock up beer"}}}

      assert_fail ctx, [:title]
      #~skip
      assert_equal %{{:params=>{:memo=>{:content=>\"Stock up beer\"}}}}, ctx.inspect
      #~skip end
    end
    #:ctx-exclude end

    it "allows {:exclude} and merge into {params}" do
      #:ctx-exclude-params-merge
      ctx = Ctx({params: {memo: {tag_list: "todo"}}}, exclude: [:title])
      #=> {:params=>{:memo=>{:content=>"Stock up beer", :tag_list=>"todo"}}}
      #:ctx-exclude-params-merge end

      assert_equal ctx.inspect, %({:params=>{:memo=>{:content=>"Stock up beer", :tag_list=>"todo"}}})
    end

    #:ctx-exclude-merge
    it "provides {Ctx()}" do
      ctx = Ctx({current_user: yogi}, exclude: [:title])
      #=> {:params=>{:memo=>{:content=>"Stock up beer"}},
      #    :current_user=>#<User name="Yogi">}
      #~skip
      assert_equal ctx.inspect, %({:params=>{:memo=>{:content=>\"Stock up beer\"}}, :current_user=>\"Yogi\"})
      #~skip end
    end
    #:ctx-exclude-merge end

    it "{Ctx} provides {merge: false} to allow direct ctx building without any automatic merging" do
      ctx = Ctx({current_user: yogi}, merge: false)

      assert_equal %{{:current_user=>\"Yogi\"}}, ctx.inspect
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
      assert_equal %{{:params=>{:content=>\"Stock up beer\"}}}, Ctx(exclude: [:title]).inspect
      assert_equal %{{:params=>{:content=>\"Stock up beer\"}, :current_user=>Module}}, Ctx({current_user: Module}, exclude: [:title]).inspect
      assert_equal %{{:params=>{:content=>\"Stock up beer\", :duration=>999}, :current_user=>Module}}, Ctx({current_user: Module, params: {duration: 999}}, exclude: [:title]).inspect
    end
  end # SongOperation_OMIT_KEY_Test


  #:assert_pass
  describe "Create with sane data" do
    # What are we passing into the operation?
    let(:default_ctx) do
      {
        params: {
          song: { # Note the {song} key here!
            band:  "Rancid",
            title: "Timebomb",
          }
        }
      }
    end

    # What will the model look like after running the operation?
    let(:expected_attributes) do
      {
        band:   "Rancid",
        title:  "Timebomb",
      }
    end

    let(:operation)     { Song::Operation::Create }
    let(:key_in_params) { :song }

    # valid default input, works
    it { assert_pass( {}, {} ) }

    # Check if {:title} can be overridden
    it { assert_pass( {title: "Ruby Soho"}, {title: "Ruby Soho"} ) }
    # Assert if automatic trimming works...
    # Check if coercing works..

    # Check if validations work
    it { assert_fail?( {band: ""}, [:band] ) }

    it do
      assert_pass( {title: "Ruby Soho"}, {title: "Ruby Soho"} ) do |result|
        assert_equal "Rancid", result[:model].band
      end
    end

    it do
      assert_fail( {band: ""}, [:band] ) do |result|
        assert_nil result[:model].band
        # puts result[:"contract.default"].errors.messages # Yes, this is good for debugging!
      end
    end
  end

  class PassFailTestWithoutSettings < OperationSpec
    it "allows to pass the entire context without any automatic merging" do
      assert_pass Ctx({params: {song: {title: "Ruby Soho", band: "Rancid"}}}, merge: false),
        {title: "Ruby Soho", band: "Rancid"},
        operation: Song::Operation::Create, default_ctx: {}
    end

    it "what" do
      assert_pass( {title: "Ruby Soho", band: "Rancid"}, {}, operation: Song::Operation::Create, key_in_params: :song )
    end

    it "what" do
      assert_pass( {song: {title: "Ruby Soho", band: "Rancid"}}, {}, operation: Song::Operation::Create )
    end
  end

  class Test < Minitest::Spec
    def call
      run
      @failures
    end

    Trailblazer::Test::Assertion.module!(self, suite: true)
  end

  it "gives colored error messages for {assert_pass} and {assert_fail}" do
    test =
      Class.new(Test) {
        # What are we passing into the operation?
        let(:default_ctx) do
          {
            params: {
              song: { # Note the {song} key here!
                band:  "Rancid",
                title: "Timebomb",
              }
            }
          }
        end

        # What will the model look like after running the operation?
        let(:expected_attributes) do
          {
            band:   "Rancid",
            title:  "Timebomb",
          }
        end

        let(:operation)     { DocsSuiteAssertionsTest::Song::Operation::Create }
        let(:key_in_params) { :song }

        # Assertion fails since {:title} doesn't have errors set.
        it { assert_fail( {band: ""}, [:band, :title] ) } #1

        # 2) Assertion fails because {title}s don't match.
        it { assert_pass( {title: "Ruby Soho"}, {title: "ruby soho"} ) }

        # Assertion fails because validation error.
        it { assert_pass( {band: ""}, {title: "Ruby Soho"} ) }

        # Test if block is called
        it do #4
          assert_pass( {band: "Millencolin"}, {band: "Millencolin"} ) do |result|
            @_m = result[:model].inspect
          end
        end

        it do #5
          assert_fail({band: ""}, [:band]) do |result|
            assert_nil result[:model].title
            @_m = result[:"contract.default"].errors.messages.inspect
          end
        end

        # Test: Block shouldn't be called when assertions before failed.
        it do #6
          assert_pass( {band: "Millencolin"}, {band: "NOFX"} ) do |result|
            @_m = result[:model].inspect
          end
        end

      # Can we override all let() options?
      # Do {assert_fail} and {assert_pass} both return {result}?
      # Can we use OPs without `contract.errors`?
        class Overrider < Trailblazer::Operation
          step ->(ctx, params:, **) { ctx[:model] = Song.new(params[:band], params[:title], params[:duration]) }
          step ->(ctx, **) { puts ctx.inspect;true }
          step ->(ctx, model:, **) { model.band.size > 0 } # pseudo validation
          fail ->(ctx, **) { ctx[:"contract.default"] = Struct.new(:errors).new(Struct.new(:messages).new({band: [1]})) }
        end
        it do #7
          @result = assert_pass( {band: "NOFX"}, {band: "NOFX"}, operation: Overrider, key_in_params: false, expected_attributes: {title: "The Brews", duration: 99}, default_ctx: {params: {duration: 99, title: "The Brews"}} )
        end
        it do #8
          @result = assert_fail?( {band: ""}, [:band], operation: Overrider, key_in_params: false, expected_attributes: {title: "The Brews", duration: 99}, default_ctx: {params: {duration: 99, title: "The Brews", band: "NOFX"}} )
        end

      # Allow passing injection variables etc.
        it do #9
          current_user = "Lola"
          @result_1 = assert_pass( Ctx({current_user: current_user, params: {band: "Rancid"}}, key_in_params: false, default_ctx: {params: {title: "Timebomb"}}), {band: "Rancid"}, operation: Overrider, key_in_params: false )
        end

        # 10) Assertion errors because of valid input.
        it { assert_fail( {band: "NOFX"}, {title: "The Brews"} ) }

        # 11) We use wtf?
        it { assert_pass?( {title: "Ruby Soho"}, {title: "Ruby Soho"} ) }
        # 12) we DON'T use wtf?
        it { assert_pass( {title: "Ruby Soho"}, {title: "Ruby Soho"} ) }
        # 13) assert_fail uses wtf?
        it { assert_fail?( {title: ""}, [:title] ) }
        # 14) assert_fail DOESN'T use {wtf?} per default
        it { assert_fail( {title: ""}, [:title] ) }

        # 15) Assertion errors because errors don't match
        it { assert_fail( {title: "Ruby Soho", band: nil}, {band: "here is an error"} ) }

        # 16) {assert_pass} returns result
        it { @result = assert_pass( {}, {} ) }
        # 17) {assert_pass} with block returns result
        it { @result = assert_pass( {}, {} ) { |result| assert result } }
        # 18) {assert_fail} returns result
        it { @result = assert_fail( {band: ""}, [:band] ) }
        # 19) {assert_fail} with block returns result
        it { @result = assert_fail( {band: ""}, [:band] ) { |result| assert result } }

        # DISCUSS: do we want to allow this keyword interface for {#assert_pass}?
        # # 20) {assert_pass} with expected_attributes as kwargs
        # it { @result = assert_pass( {}, title: "Cocktails") }
        # # 21) {assert_pass?} with wtf?
        # it { @result = assert_pass?( {}, title: "Cocktails") }

      } # Test

test_1 = test.new(:test_0001_anonymous)
      failures = test_1.()

      # {assert_fail} sees less errors than the user specified: The errors are colored.
      failures[0].inspect.must_equal %{#<Minitest::Assertion: Actual contract errors: \e[33m{:band=>["must be filled"]}\e[0m.
Expected: [:band, :title]
  Actual: [:band]>}

      assert_equal 1, failures.size





test_2 = test.new(:test_0002_anonymous)
      failures = test_2.()

      # {assert_pass} complains because {title} doesn't match
      failures[0].inspect.must_equal %{#<Minitest::Assertion: Property [title] mismatch.
Expected: "ruby soho"
  Actual: "Ruby Soho">}

      assert_equal 1, failures.size






test_3 = test.new(:test_0003_anonymous)
      failures = test_3.()

      # {assert_pass} complains because {title} doesn't match
      failures[0].inspect.must_equal %{#<Minitest::Assertion: {Trailblazer::Test::Testing::Song::Operation::Create} failed: \e[33m{:band=>[\"must be filled\"]}\e[0m.
Expected: true
  Actual: false>}



# You can see {ctx[:"contract.default"]} in the {#assert_pass} block.
test_4 = test.new(:test_0004_anonymous)
      failures = test_4.()

      failures[0].must_equal nil
      test_4.instance_variable_get(:@_m).must_equal %{#<struct Trailblazer::Test::Testing::Song band=\"Millencolin\", title=\"Timebomb\", duration=nil>}
      assert_equal 3, test_4.instance_variable_get(:@assertions)
# pass block is not run when assertion failed before
test_6 = test.new(:test_0006_anonymous)
      failures = test_6.()
      assert_equal 2, test_6.instance_variable_get(:@assertions)
      failures[0].inspect.must_equal %{#<Minitest::Assertion: Property [band] mismatch.
Expected: "NOFX"
  Actual: "Millencolin">}
      assert_nil test_6.instance_variable_get(:@_m) # no block called.

# You can see {ctx[:"contract.default"]} in the {#assert_fail} block.
test_5 = test.new(:test_0005_anonymous)
      failures = test_5.()

      assert_nil failures[0]
      assert_equal test_5.instance_variable_get(:@_m), %({:band=>[\"must be filled\"]})
      assert_equal 3, test_5.instance_variable_get(:@assertions)

# Can we override all let() options?
test_7 = test.new(:test_0007_anonymous)
      failures = test_7.()

      assert_nil failures[0]
      assert_equal 1, test_7.instance_variable_get(:@assertions)
      assert_equal %{#<struct Trailblazer::Test::Testing::Song band=\"NOFX\", title=\"The Brews\", duration=99>}, test_7.instance_variable_get(:@result)[:model].inspect
      # same for assert_fail
test_8 = test.new(:test_0008_anonymous)
      failures = test_8.()

      assert_equal %{nil}, failures[0].inspect
      assert_equal 2, test_8.instance_variable_get(:@assertions)
      assert_equal %{#<struct Trailblazer::Test::Testing::Song band=\"\", title=\"The Brews\", duration=99>}, test_8.instance_variable_get(:@result)[:model].inspect

test_9 = test.new(:test_0009_anonymous)
      failures = test_9.()

      assert_equal %{nil}, failures[0].inspect
      assert_equal 1, test_9.instance_variable_get(:@assertions)
      assert_equal %{<Result:true #<Trailblazer::Context::Container wrapped_options={:params=>{:title=>\"Timebomb\", :band=>\"Rancid\"}, :current_user=>\"Lola\"} mutable_options={:model=>#<struct Trailblazer::Test::Testing::Song band=\"Rancid\", title=\"Timebomb\", duration=nil>}> >},
        test_9.instance_variable_get(:@result_1).inspect

# When the operation passes but it should fail.
test_10 = test.new(:test_0010_anonymous)
      failures = test_10.()

      assert_equal %{#<Minitest::Assertion: {Trailblazer::Test::Testing::Song::Operation::Create} didn't fail, it passed.
Expected: false
  Actual: true>}, failures[0].inspect
      assert_equal 1, test_10.instance_variable_get(:@assertions)
      # assert_nil test_10.instance_variable_get(:@result_1)

# {assert_pass} uses wtf?.
test_11 = test.new(:test_0011_anonymous)
      output = capture_io do
        failures = test_11.()
      end

      assert_equal %(Trailblazer::Test::Testing::Song::Operation::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel.build\e[0m
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[32mcontract.default.call\e[0m
|   `-- End.success
|-- \e[32mparse_duration\e[0m
|-- \e[32mpersist.save\e[0m
`-- End.success
),
        output.join("")
      assert_nil failures[0]
      assert_equal 1, test_11.instance_variable_get(:@assertions)
# {assert_pass} DOES NOT use wtf? per default.
test_12 = test.new(:test_0012_anonymous)
      output = capture_io { failures = test_12.() }

      assert_equal %{}, output.join("")
      assert_nil failures[0]
      assert_equal 1, test_12.instance_variable_get(:@assertions)
test_13 = test.new(:test_0013_anonymous)
      output = capture_io { failures = test_13.() }

      assert_equal %(Trailblazer::Test::Testing::Song::Operation::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel.build\e[0m
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[33mcontract.default.call\e[0m
|   `-- End.failure
`-- End.failure
), output.join("")
      assert_nil failures[0]
      assert_equal 2, test_13.instance_variable_get(:@assertions)
test_14 = test.new(:test_0014_anonymous)
      output = capture_io { failures = test_14.() }

      assert_equal %{}, output.join("")
      assert_nil failures[0]
      assert_equal 2, test_14.instance_variable_get(:@assertions)

test_15 = test.new(:test_0015_anonymous)
      output = capture_io { failures = test_15.() }

      assert_equal %{}, output.join("")
      failures[0].inspect.must_equal %{#<Minitest::Assertion: Actual contract errors: \e[33m{:band=>[\"must be filled\"]}\e[0m.
Expected: {:band=>[\"here is an error\"]}
  Actual: {:band=>[\"must be filled\"]}>}
      assert_equal 2, test_14.instance_variable_get(:@assertions)

  test_16 = test.new(:test_0016_anonymous)
      output = capture_io { failures = test_16.() }
      assert_equal %{}, output.join("")
      assert_nil failures[0]
      assert_equal 1, test_16.instance_variable_get(:@assertions)
      assert_equal %{Trailblazer::Operation::Railway::Result}, test_16.instance_variable_get(:@result).class.inspect

  test_17 = test.new(:test_0017_anonymous)
      output = capture_io { failures = test_17.() }
      assert_equal %{}, output.join("")
      assert_nil failures[0]
      assert_equal 2, test_17.instance_variable_get(:@assertions)
      assert_equal %{Trailblazer::Operation::Railway::Result}, test_16.instance_variable_get(:@result).class.inspect

  test_18 = test.new(:test_0018_anonymous)
      output = capture_io { failures = test_18.() }
      assert_equal %{}, output.join("")
      assert_nil failures[0]
      assert_equal 2, test_18.instance_variable_get(:@assertions)
      assert_equal %{Trailblazer::Operation::Railway::Result}, test_18.instance_variable_get(:@result).class.inspect

  test_19 = test.new(:test_0019_anonymous)
      output = capture_io { failures = test_19.() }
      assert_equal %{}, output.join("")
      assert_nil failures[0]
      assert_equal 3, test_19.instance_variable_get(:@assertions)
      assert_equal %{Trailblazer::Operation::Railway::Result}, test_19.instance_variable_get(:@result).class.inspect

  # DISCUSS: do we want to allow this keyword interface for {#assert_pass}?
  # test_20 = test.new(:test_0020_anonymous)
  #     output = capture_io { failures = test_20.() }
  #     assert_equal %{}, output.join("")
  #     assert_nil failures[0]

  #   test_21 = test.new(:test_0021_anonymous)
  #     output = capture_io { failures = test_21.() }
  #     assert_equal %{}, output.join("")
  #     assert_nil failures[0]
  end
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
