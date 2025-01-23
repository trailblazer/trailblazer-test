require "test_helper"

class AssertionsTest < Minitest::Spec
  # UNCOMMENT for quick debugging.
  # Trailblazer::Test::Assertion.module!(self)
  it "#assert_pass" do
# assert_pass? Create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond"

    test =
      Class.new(Test) do
        Trailblazer::Test::Assertion.module!(self)
        Memo = Trailblazer::Test::Testing::Memo
        Create = Memo::Operation::Create

        VALID_INPUT = Memo::VALID_INPUT # {params: {memo: {title: "TODO", content: "Stock up beer"}}}

        # 01
        # fails, expected {content} mismatch.
        it do
          @result = assert_pass Create, VALID_INPUT,
            # expected:
            title: "TODO",
            content: "" # this is wrong.
        end

        # 02
        # passes.
        it do
          @result = assert_pass Create, VALID_INPUT,
            # expected:
            title: "TODO",
            content: "Stock up beer"
        end

        # 03
        # block, passes.
        it do
          assert_pass Create, VALID_INPUT do |result|
            @result = result

            assert_equal result[:model].class, Memo
          end
        end

        # 04
        # block fails
        it do
          assert_pass Create, VALID_INPUT do |result|
            @result = result
            assert_equal result[:model].class, "Song" # fails.
          end
        end

        # 05
        # We accept {:invoke_method} as a first level kw arg, currently.
        it do
          stdout, _ = capture_io do
            @result = assert_pass Create, VALID_INPUT, title: "TODO", invoke: Trailblazer::Test::Assertion.method(:invoke_operation_with_wtf)
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

        # 06
        # We accept {:model_at} as a first level kw arg, currently.
        it do
          create = Class.new(Trailblazer::Operation) do
            include Memo::Operation::Create::Capture
            step :capture
            step :model

            def model(ctx, params:, **)
              ctx[:memo] = Memo.new(**params[:memo])
            end
          end

          @result = assert_pass create, VALID_INPUT, title: "TODO", model_at: :memo
          # assert_pass Create, {params: {title: "Somewhere Far Beyond"}}, {invoke_method: :wtf?, model_at: }, {...} # DISCUSS: this would be an alternative syntax.
        end

        # 07
        # {#assert_pass} returns {result}.
        it do
          @result = assert_pass Create, VALID_INPUT, title: "TODO"

          assert_equal @result[:model].title, "TODO"
        end

        # 08
        # {#assert_pass?}
        it do
          stdout, _ = capture_io do
            @result = assert_pass? Create, VALID_INPUT, title: "TODO"

            assert_equal @result[:model].title, "TODO"
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
      end

    assert_test_case_fails(test, "01", %(Property [content] mismatch.
Expected: ""
  Actual: "Stock up beer"))
    assert_test_case_passes(test, "02", input = %({:params=>{:memo=>{:title=>\"TODO\", :content=>\"Stock up beer\"}}}))
    assert_test_case_passes(test, "03", input)
    assert_test_case_fails(test, "04", %(--- expected
+++ actual
@@ -1 +1 @@
-Trailblazer::Test::Testing::Memo(keyword_init: true)
+"Song"
))
    assert_test_case_passes(test, "05", input)
    assert_test_case_passes(test, "06", input)
    assert_test_case_passes(test, "07", input)
    assert_test_case_passes(test, "08", input)
  end

          # include Trailblazer::Test::Assertion
  it "#assert_fail" do
        # assert_fail Update, {params: {bla: 1}}, [:title]
        # assert_fail Update, {params: {bla: 1}} do |result|
        # end

    test =
      Class.new(Test) do
        Trailblazer::Test::Assertion.module!(self)
        Memo = Trailblazer::Test::Testing::Memo
        Create = Memo::Operation::Create
        VALID_INPUT = Memo::VALID_INPUT # {params: {memo: {title: "TODO", content: "Stock up beer"}}}

        # 01
        # Create fails, we provide [:errors]
        it do
          @result = assert_fail Create, {params: {memo: {title: nil}}},
            # expected:
            [:title, :content]
        end

        # 02
        # Create fails, we provide {errors: []}
        it do
          @result = assert_fail Create, {params: {memo: {title: nil}}},
            # expected:
            {title: ["must be filled"], content: ["must be filled", "size cannot be less than 8"]}
        end

        # 03
        # throws, Create actually passes.
        it do
          assert_fail Create, VALID_INPUT, [:title]
        end

        # 04
        # errors mismatch.
        it do
          assert_fail Create, {params: {memo: {title: nil}}},
            # expected:
            {title: ["is XXX"]} # this is wrong.
        end

        # 05
        # block style
        it do
          assert_fail Create, {params: {memo: {title: nil}}} do |result|
            @result = result
            assert_equal result[:"contract.default"].errors.messages, {title: ["must be filled"], content: ["must be filled", "size cannot be less than 8"]}
          end
        end

        # 06
        # actually passes, block not executed
        it do
          assert_fail Create, VALID_INPUT do |result| # this actually passes.
            raise result.inspect
          end
        end

        # 07
        # both expected_errors and block are considered.
        it do
          assert_fail Create, {params: {memo: {title: nil}}}, [:title, :content] do |result|
            assert_equal result[:"contract.default"].errors.messages, {title: ["must be filled"], content: ["must be filled", "size cannot be less than 8"]}
            @result = result
          end
        end

        # 08
        # {expected_errors} is wrong, block not executed.
        it do
          assert_fail Create, {params: {memo: {title: nil}}}, [:title] do |result|
            raise result.inspect
          end
        end

        # 09
        # expected_errors subset is wrong
        it do
          assert_fail Create, {params: {memo: {title: nil}}}, [:title, :XXX] do |result|
            raise result.inspect
          end
        end

        # 10
        # we allow {:invoke}.
        it do
          stdout, _ = capture_io do
            @result = assert_fail Create, {params: {memo: {title: nil}}}, [:title, :content], invoke: Trailblazer::Test::Assertion.method(:invoke_operation_with_wtf)
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
|   |-- \e[33mcontract.default.call\e[0m
|   `-- End.failure
`-- End.failure
)
        end

        # 11
        # {#assert_fail} returns {result}.
        it do
          @result = assert_fail Create, {params: {memo: {title: nil}}}, [:title, :content]
          assert_equal CU.inspect(@result[:"contract.default"].errors.messages), %({:title=>[\"must be filled\"], :content=>["must be filled", "size cannot be less than 8"]})
        end

        # 12
        # {#assert_fail} can be used without contract errors.
        it do
          operation = Class.new(Trailblazer::Operation) do
            include Memo::Operation::Create::Capture
            step :capture
            step ->(ctx, **) { false }
          end

          @result = assert_fail operation, {params: {memo: {title: nil}}}

          assert_equal @result.keys.inspect, %([:params, :captured])
        end

        # 13
        # {#assert_fail?}
        it do
          stdout, _ = capture_io do
            @result = assert_fail? Create, {params: {memo: {title: nil}}}, [:title, :content]
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
|   |-- \e[33mcontract.default.call\e[0m
|   `-- End.failure
`-- End.failure
)
        end
      end

    assert_test_case_passes(test, "01", input = %({:params=>{:memo=>{:title=>nil}}}))
    assert_test_case_passes(test, "02", input)
    assert_test_case_fails(test, "03", %({Trailblazer::Test::Testing::Memo::Operation::Create} didn't fail, it passed.
Expected: false
  Actual: true))
    assert_test_case_fails(test, "04", %(Actual contract errors: \e[33m{:title=>[\"must be filled\"], :content=>[\"must be filled\", \"size cannot be less than 8\"]}\e[0m.
--- expected
+++ actual
@@ -1 +1 @@
-{:title=>[\"is XXX\"]}
+{:title=>[\"must be filled\"], :content=>[\"must be filled\", \"size cannot be less than 8\"]}
))
    assert_test_case_passes(test, "05", input)
    assert_test_case_fails(test, "06", %({Trailblazer::Test::Testing::Memo::Operation::Create} didn't fail, it passed.
Expected: false
  Actual: true))
    assert_test_case_passes(test, "07", input)
assert_test_case_fails(test, "08", %(Actual contract errors: \e[33m{:title=>[\"must be filled\"], :content=>[\"must be filled\", \"size cannot be less than 8\"]}\e[0m.
Expected: [:title]
  Actual: [:content, :title]))
assert_test_case_fails(test, "09", %(Actual contract errors: \e[33m{:title=>[\"must be filled\"], :content=>[\"must be filled\", \"size cannot be less than 8\"]}\e[0m.
Expected: [:XXX, :title]
  Actual: [:content, :title]))
    assert_test_case_passes(test, "10", input)
    assert_test_case_passes(test, "11", input)
    assert_test_case_passes(test, "12", input)
    assert_test_case_passes(test, "13", input)
  end
end
