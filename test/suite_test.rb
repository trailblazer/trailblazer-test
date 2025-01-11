require "test_helper"

# Brutal unit tests for Suite.
class SuiteTest < Minitest::Spec
  Record = Struct.new(:id, :persisted?, :title, :genre, keyword_init: true)

  class Test < Minitest::Spec
    def call
      run
      return @failures, @assertions, @result
    end
  end

  # UNCOMMENT for quick debugging.
  # Trailblazer::Test::Assertion.module!(self, suite: true)
  # let(:operation) { Trailblazer::Test::Testing::Memo::Operation::Create }
  # let(:default_ctx) { {params: {memo: {title: "Note to self", content: "Remember me!"}}} }
  # let(:expected_attributes) { {content: "Remember me!", persisted?: true} }
  # let(:key_in_params) { :memo }
  # it "what" do
  #   assert_fail({title: nil}, {title: ["is missing"]})
  # end

  it "#assert_pass" do
    test =
      Class.new(Test) do
        Memo = Trailblazer::Test::Testing::Memo

        # 1. Test the merging behavior of Suite's assertions by inspecting the incoming {ctx}.
        # 2. Test result's arity by running assert_pass with a failing OP.
        # 3. test different manual input vs different expected_attributes to see if all attributes are tested.

        Trailblazer::Test::Assertion.module!(self, suite: true)

        let(:operation) { Memo::Operation::Create }
        let(:default_ctx) { {params: {memo: {title: "Note to self", content: "Remember me!"}}} }
        let(:expected_attributes) { {title: "Note to self", content: "Remember me!"} }
        let(:key_in_params) { :memo }

        # 01
        # allows empty hashes
        it do
          @result = assert_pass({}, {})
        end

        # 02
        # does {result.success?} assertion work?
        it do
          @result = assert_pass({title: ""}, {})
        end

      # indirect assert_exposes tests
        # 03
        # differing input and default expected_attributes. (assert_exposes error)
        it do
          @result = assert_pass({title: "let's break"}, {})
        end

        # 04
        # differing default_ctx and manual passed expected_attributes. (assert_exposes error)
        it do
          @result = assert_pass({}, {title: "Forgot"})
        end

        # 05
        # inputs matches
        it do
          @result = assert_pass({content: "don't forget"}, {content: "don't forget"})
        end

        # 06
        # inputs don't match, (assert_exposes error)
        it do
          @result = assert_pass({content: "don't forget"}, {content: "This is slightly different"})
        end

        # DISCUSS: should we also test a "wrong" let(:expected_attributes)

      # syntactical tests
        # 07
        # returns {result}.
        it do
          @result = assert_pass({}, {})

          assert_equal @result[:model].title, "Note to self"
        end

        # 08
        # we can override default_ctx variables and add new attributes.
        it do
          @result = assert_pass(
            {title: "Simple memo", tag_list: "todo,today"},
            {title: "Simple memo", tag_list: ["todo", "today"]}
          )

          assert_equal @result[:model].title, "Simple memo"
          assert_equal @result[:model].tag_list, ["todo", "today"]
        end

        # 09
        # allows block.
        it do
          assert_pass({}, {}) do |result|
            @result = result # tests if this block is executed.
            assert_equal result[:model].title, "Note to self"
          end
        end

        # 10
        # We accept {:invoke_method} as a first level kw arg, currently.
        it do
          stdout, _ = capture_io do
            @result = assert_pass({}, {}, invoke: Trailblazer::Test::Assertion.method(:invoke_operation_with_wtf))
          end

          stdout = stdout.sub(/0x\w+/, "XXX")

          assert_equal stdout, %(Trailblazer::Test::Testing::Memo::Operation::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mcapture\e[0m
|-- model.build
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32m#<Trailblazer::Macro::Model::Find::NoArgument:XXX>\e[0m
|   `-- End.success
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[32mcontract.default.call\e[0m
|   `-- End.success
|-- \e[32mparse_tag_list\e[0m
|-- \e[32mpersist.save\e[0m
`-- End.success
)
        end

        Test_for_ModelAt = describe ":model_at" do
          let(:operation) do
            Class.new(Trailblazer::Operation) do
              include Memo::Operation::Create::Capture
              step :capture
              step :model

              def model(ctx, params:, **)
                ctx[:record] = Memo.new(**params[:memo])
              end
            end
          end

          # 01
          # We accept {:model_at} as a first level kw arg, currently.
          it do
            @result = assert_pass({title: "Done"}, {title: "Done"}, model_at: :record)
          end
        end

        # 11
        # {#assert_pass?}
        it do
          stdout, _ = capture_io do
            @result = assert_pass?({title: "Done"}, {title: "Done"})
          end

          stdout = stdout.sub(/0x\w+/, "XXX")

          assert_equal stdout, %(Trailblazer::Test::Testing::Memo::Operation::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mcapture\e[0m
|-- model.build
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32m#<Trailblazer::Macro::Model::Find::NoArgument:XXX>\e[0m
|   `-- End.success
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[32mcontract.default.call\e[0m
|   `-- End.success
|-- \e[32mparse_tag_list\e[0m
|-- \e[32mpersist.save\e[0m
`-- End.success
)
        end

        Test_assert_fail = describe "{#assert_fail}" do
          # 01
          # validation error
          it do
            @result = assert_fail({title: nil, content: nil}, [:title, :content])
          end

          # 02
          # test that we merge first argument with default_ctx.
          it do
            @result = assert_fail({title: nil, urgency: 1}, [:title])
          end

          # 03
          # no second argument necessary.
          # TODO: implement.
          it do
            @result = assert_fail({title: nil})
          end

          # 04
          # with explicit error messages.
          it do
            @result = assert_fail({title: nil}, {title: ["must be filled"]})
          end

          # 05
          # with incorrect error message.
          it do
            @result = assert_fail({title: nil}, {title: ["--> this is wrong <--"]})
          end

          # 06
          # block style, no automatic contract error checks.
          it do
            assert_fail({title: nil}) do |result|
              @result = result # test this block is executed.
              assert_equal result[:"contract.default"].errors.messages, {:title=>["must be filled"]}
            end
          end
        end
      end

    def assert_test_case_passes(test, number, input)
      test_case = test.new(:"test_00#{number}_anonymous")
      failures, assertions, result = test_case.()

      puts failures if failures.size > 0 # TODO: this is an automatic "debugger" :D
      assert_equal failures.size, 0
      # assert_equal assertions, assertion_count

      assert_equal result[:captured], input
    end

    def assert_test_case_fails(test, number, error_message)
      test_case = test.new(:"test_00#{number}_anonymous")
      failures, assertions, _ = test_case.()

      assert_equal failures.size, 1
      assert_equal failures[0].inspect, error_message
    end

    # assert_pass {}, {}
    assert_test_case_passes(test, "01", input = %({:params=>{:memo=>{:title=>\"Note to self\", :content=>\"Remember me!\"}}}))
    assert_test_case_fails(test, "02", %(#<Minitest::Assertion: {Trailblazer::Test::Testing::Memo::Operation::Create} failed: \e[33m{:title=>[\"must be filled\"]}\e[0m.
Expected: true
  Actual: false>))
    assert_test_case_fails(test, "03", %(#<Minitest::Assertion: Property [title] mismatch.
Expected: \"Note to self\"
  Actual: \"let's break\">))
    assert_test_case_fails(test, "04", %(#<Minitest::Assertion: Property [title] mismatch.
Expected: \"Forgot\"
  Actual: \"Note to self\">))
    assert_test_case_passes(test, "05", %({:params=>{:memo=>{:title=>\"Note to self\", :content=>\"don't forget\"}}}))
    assert_test_case_fails(test, "06", %(#<Minitest::Assertion: Property [content] mismatch.
Expected: \"This is slightly different\"
  Actual: \"don't forget\">))
    assert_test_case_passes(test, "07", input)
    assert_test_case_passes(test, "08", %({:params=>{:memo=>{:title=>\"Simple memo\", :content=>\"Remember me!\", :tag_list=>\"todo,today\"}}}))
    assert_test_case_passes(test, "09", input)
    assert_test_case_passes(test, "10", input)
    assert_test_case_passes(Test_for_ModelAt, "01", %({:params=>{:memo=>{:title=>\"Done\", :content=>\"Remember me!\"}}}))
    assert_test_case_passes(test, "11", %({:params=>{:memo=>{:title=>\"Done\", :content=>\"Remember me!\"}}}))

    # assert_fail
    assert_test_case_passes(Test_assert_fail, "01", %({:params=>{:memo=>{:title=>nil, :content=>nil}}}))
    assert_test_case_passes(Test_assert_fail, "02", %({:params=>{:memo=>{:title=>nil, :content=>\"Remember me!\", :urgency=>1}}}))
    assert_test_case_passes(Test_assert_fail, "03", %({:params=>{:memo=>{:title=>nil, :content=>"Remember me!"}}}))
    assert_test_case_passes(Test_assert_fail, "04", %({:params=>{:memo=>{:title=>nil, :content=>"Remember me!"}}}))
    assert_test_case_fails(Test_assert_fail, "05", %{#<Minitest::Assertion: Actual contract errors: \e[33m{:title=>[\"must be filled\"]}\e[0m.
--- expected
+++ actual
@@ -1 +1 @@
-{:title=>[\"--> this is wrong <--\"]}
+{:title=>[\"must be filled\"]}
>})
    assert_test_case_passes(Test_assert_fail, "06", %({:params=>{:memo=>{:title=>nil, :content=>"Remember me!"}}}))
  end

  it "#assert_fail" do
    test =
      Class.new(Test) do
        Trailblazer::Test::Assertion.module!(self)


        # test_0005_anonymous
        it do
          assert_fail Update, {params: {title: nil}} do |result|
            @_m = true
            assert_equal result[:"contract.default"].errors.messages, {:title=>["is missing"]}
          end
        end

        # test_0006_anonymous
        it do
          assert_fail Update, {params: {record: true}} do |result| # this actually passes.
            @_m = true
          end
        end

        # test_0007_anonymous
        # both expected_errors and block are considered.
        it do
          assert_fail Update, {params: {title: nil}}, [:title] do |result|
            assert_equal result[:"contract.default"].errors.messages, {:title=>["is missing"]}
            @_m = true
          end
        end

        # test_0008_anonymous
        # expected_errors is wrong
        it do
          assert_fail Update, {params: {title: nil}}, [:title_XXX] do |result|
            @_m = true
          end
        end

        # test_0009_anonymous
        it do
          stdout, _ = capture_io do
            assert_fail Update, {params: {title: nil}}, [:title], invoke: Trailblazer::Test::Assertion.method(:invoke_operation_with_wtf)
          end

          assert_equal stdout, %(AssertionsTest::Update\n|-- \e[32mStart.default\e[0m\n|-- \e[33mvalidate\e[0m\n`-- End.failure\n)
        end

        # test_0010_anonymous
        # {#assert_fail} returns {result}.
        it do
          result = assert_fail Update, {params: {title: nil}}, [:title]
          assert_equal CU.inspect(result[:"contract.default"].errors.messages), %({:title=>[\"is missing\"]})
        end

        # test_0011_anonymous
        # {#assert_fail} can be used without contract errors.
        it do
          operation = Class.new(Trailblazer::Operation) do
            step ->(ctx, **) { false }
          end

          result = assert_fail operation, {params: {title: nil}}

          assert_equal result.keys.inspect, %([:params])
        end

        # test_0012_anonymous
        it do
          stdout, _ = capture_io do
            assert_fail? Update, {params: {title: nil}}, [:title]
          end

          assert_equal stdout, %(AssertionsTest::Update\n|-- \e[32mStart.default\e[0m\n|-- \e[33mvalidate\e[0m\n`-- End.failure\n)
        end
      end

      raise "what if assert_fail errors are only subset of user's?"

    test_1 = test.new(:test_0001_anonymous)
    failures = test_1.()
    assert_equal failures.size, 0

    test_2 = test.new(:test_0002_anonymous)
    failures = test_2.()
    assert_equal failures.size, 0

    test_3 = test.new(:test_0003_anonymous)
    failures = test_3.()
    assert_equal failures.size, 1
    assert_equal failures[0].inspect, %(#<Minitest::Assertion: {AssertionsTest::Update} didn't fail, it passed.
Expected: false
  Actual: true>)

    test_4 = test.new(:test_0004_anonymous)
    failures = test_4.()
    assert_equal failures.size, 1
    assert_equal failures[0].inspect, %(#<Minitest::Assertion: Actual contract errors: \e[33m{:title=>[\"is missing\"]}\e[0m.
Expected: {:title=>[\"is XXX\"]}
  Actual: {:title=>[\"is missing\"]}>)

    test_5 = test.new(:test_0005_anonymous)
    failures = test_5.()
    assert_equal test_5.instance_variable_get(:@_m), true
    assert_equal failures.size, 0

    test_6 = test.new(:test_0006_anonymous)
    failures = test_6.()
    assert_nil test_6.instance_variable_get(:@_m) # block is not executed.
    assert_equal failures.size, 1
    assert_equal failures[0].inspect, %(#<Minitest::Assertion: {AssertionsTest::Update} didn't fail, it passed.
Expected: false
  Actual: true>)

    test_7 = test.new(:test_0007_anonymous)
    failures = test_7.()
    assert_equal test_7.instance_variable_get(:@_m), true
    assert_equal failures.size, 0

    test_8 = test.new(:test_0008_anonymous)
    failures = test_8.()
    assert_nil test_8.instance_variable_get(:@_m) # block is not executed.
    assert_equal failures.size, 1
    assert_equal failures[0].inspect, %(#<Minitest::Assertion: Actual contract errors: \e[33m{:title=>[\"is missing\"]}\e[0m.
Expected: [:title_XXX]
  Actual: [:title]>)

    test_9 = test.new(:test_0009_anonymous)
    failures = test_9.()
    assert_equal failures.size, 0

    test_10 = test.new(:test_0010_anonymous)
    failures = test_10.()
    assert_equal failures.size, 0

    test_11 = test.new(:test_0011_anonymous)
    failures = test_11.()
    assert_equal failures.size, 0

    test_12 = test.new(:test_0012_anonymous)
    failures = test_12.()
    assert_equal failures.size, 0
  end
end

class AssertionActivityTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self, activity: true)

  Record = Trailblazer::Test::Testing::Memo

  class Create < Trailblazer::Activity::FastTrack
    step :validate
    step :model

    def validate(ctx, params:, **)
      return true if params[:title]

      ctx[:"contract.default"] = Struct.new(:errors).new(Struct.new(:messages).new({:title => ["is missing"]}))
      false
    end

    def model(ctx, params:, **)
      ctx[:model] = Record.new(**params)
    end
  end

  it do
    assert_pass Create, {params: {title: "Roxanne"}},
      title: "Roxanne"
  end

  it do
    assert_fail Create, {params: {}}, [:title]
  end
end

# Test with the Assertion::Suite "DSL" module.
class SuiteWithActivityTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self, activity: true, suite: true)
  # Record = AssertionsTest::Record
  # Create = AssertionActivityTest::Create

  let(:operation) { Create }

  it do
    out, _ = capture_io do
      assert_pass?({title: "Roxanne"}, {title: "Roxanne"})
    end

    assert_equal out, %(AssertionActivityTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mvalidate\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
)
  end

  it "{#assert_fail} with wtf?" do
    out, _ = capture_io do
      assert_fail?({title: nil}, [:title])
    end

    assert_equal out, %(AssertionActivityTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[33mvalidate\e[0m
`-- End.failure
)
  end
end

require "trailblazer/endpoint"
require "trailblazer/test/endpoint"
class EndpointWithActivityTest < Minitest::Spec
    # Record = AssertionsTest::Record
    # Create = AssertionActivityTest::Create

  include Trailblazer::Test::Assertion
  include Trailblazer::Test::Assertion::Activity
  include Trailblazer::Test::Assertion::AssertExposes

  def self.__(activity, options, **kws, &block) # TODO: move this to endpoint.
    signal, (ctx, flow_options) = Trailblazer::Endpoint::Runtime.(
      activity, options,
      flow_options: _flow_options(),
      **kws,
      &block
    )

    return signal, ctx # DISCUSS: should we provide a Result object here?
  end

  def self.__?(*args, &block)
    __(*args, invoke_method: Trailblazer::Developer::Wtf.method(:invoke), &block)
  end
  include Trailblazer::Test::Endpoint.module(self, invoke_method: method(:__), invoke_method_wtf: method(:__?))


  def self._flow_options
    {
      context_options: {
        aliases: {"model": :object},
        container_class: Trailblazer::Context::Container::WithAliases,
      }
    }
  end


  it "{#assert_pass} {Activity} invoked via endpoint" do
    ctx = assert_pass Create, {params: {title: "Roxanne"}},
      title: "Roxanne"

    assert_equal ctx[:object].title, "Roxanne" # aliasing only works through endpoint.
  end

  it "{#assert_fail} with activity via endpoint" do
    ctx = assert_fail Create, {params: {}}, [:title]

    assert_equal ctx.class, Trailblazer::Context::Container::WithAliases
  end

  it "{#assert_pass?}" do
    out, _ = capture_io do
      ctx = assert_pass? Create, {params: {title: "Roxanne"}},
        title: "Roxanne"

      assert_equal ctx[:object].title, "Roxanne" # aliasing only works through endpoint.
    end

    assert_equal out, %(AssertionActivityTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mvalidate\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
)
  end

  it "{#assert_fail?}" do
    out, _ = capture_io do
      ctx = assert_fail? Create, {params: {}}, [:title]
    end

    assert_equal out, %(AssertionActivityTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[33mvalidate\e[0m
`-- End.failure
)
  end
end

