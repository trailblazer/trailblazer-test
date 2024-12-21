require "test_helper"

class AssertionsTest < Minitest::Spec
  Record = Struct.new(:id, :persisted?, :title, :genre, keyword_init: true)

  class Test < Minitest::Spec
    def call
      run
      @failures
    end

    # include Trailblazer::Test::Assertions
  end

  # Create = Trailblazer::Test::Testing::Song::Operation::Create
  class Create < Trailblazer::Operation
    step :model

    def model(ctx, params:, **)
      ctx[:model] = Record.new(**params)
    end
  end

  class Update < Trailblazer::Operation
    step :validate

    def validate(ctx, params:, **)
      return true if params[:record]

      ctx[:"contract.default"] = Struct.new(:errors).new(Struct.new(:messages).new({:title => ["is missing"]}))
      false
    end
  end

  # TODO: should we test the "meat" of these assertions here?
  it "#assert_exposes" do
    test =
      Class.new(Test) do
        include Trailblazer::Test::Assertion::AssertExposes
        # include Trailblazer::Test::Operation::Assertions

        # test_0001_anonymous
        it do
          record = Record.new(id: 1, persisted?: true)

          assert_exposes record,
            id: 1,
            persisted?: true
        end

        # test_0002_anonymous
        it do
          record = Record.new(id: 1, persisted?: true)

          assert_exposes record,
            id: 2,
            persisted?: nil
        end
      end

    test_1 = test.new(:test_0001_anonymous)
    failures = test_1.()
    assert_equal failures.size, 0

    test_2 = test.new(:test_0002_anonymous)
    failures = test_2.()
    assert_equal 1, failures.size
    assert_equal failures[0].inspect, %(#<Minitest::Assertion: Property [id] mismatch.
Expected: 2
  Actual: 1>)
  end

        include Trailblazer::Test::Assertion
        include Trailblazer::Test::Assertion::AssertExposes
  it "#assert_pass" do
# FIXME: test that assert_* returns {ctx}
assert_pass? Create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond"

    test =
      Class.new(Test) do
        include Trailblazer::Test::Assertion
        include Trailblazer::Test::Assertion::AssertExposes

        # test_0001_anonymous
        it do
          assert_pass Create, {params: {title: "Somewhere Far Beyond"}},
            # expected:
            id: 1,
            persisted?: true,
            title: "Somewhere Far Beyond",
            genre: nil
        end

        # test_0002_anonymous
        it do
          assert_pass Create, {params: {title: "Somewhere Far Beyond"}},
            # expected:
            id: nil,
            persisted?: nil,
            title: "Somewhere Far Beyond",
            genre: nil
        end

        # test_0003_anonymous
        it do
          assert_pass Create, {params: {title: "Somewhere Far Beyond"}} do |result|
            @_m = result.keys.inspect

            assert_equal result[:model].class, Record
          end
        end

        # test_0004_anonymous
        it do
          assert_pass Create, {params: {title: "Somewhere Far Beyond"}} do |result|
            assert_equal result[:model].class, "Song" # fails
          end
        end

        # test_0005_anonymous
        # We accept {:invoke_method} as a first level kw arg, currently.
        it do
          stdout, _ = capture_io do
            assert_pass Create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond", invoke: Trailblazer::Test::Assertion.method(:invoke_operation_with_wtf)
          end

          assert_equal stdout, %(AssertionsTest::Create\n|-- \e[32mStart.default\e[0m\n|-- \e[32mmodel\e[0m\n`-- End.success\n)
        end

        # test_0006_anonymous
        # We accept {:model_at} as a first level kw arg, currently.
        it do
          create = Class.new(Trailblazer::Operation) do
            step :model

            def model(ctx, params:, **)
              ctx[:song] = Record.new(**params)
            end
          end

          assert_pass create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond", model_at: :song
          # assert_pass Create, {params: {title: "Somewhere Far Beyond"}}, {invoke_method: :wtf?, model_at: }, {...} # DISCUSS: this would be an alternative syntax.
        end

        # test_0007_anonymous
        # {#assert_pass} returns {result}.
        it do
          result = assert_pass Create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond"

          assert_equal result[:model].title, "Somewhere Far Beyond"
        end

        # test_0008_anonymous
        # {#assert_pass?}
        it do
          out, _ = capture_io do
            result = assert_pass? Create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond"

            assert_equal result[:model].title, "Somewhere Far Beyond"
          end

          assert_equal out, %(AssertionsTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
)
        end
      end

    test_1 = test.new(:test_0001_anonymous)
    failures = test_1.()
    assert_equal failures.size, 1
    assert_equal failures[0].inspect, %(#<Minitest::Assertion: Property [id] mismatch.
Expected: 1
  Actual: nil>)

    test_2 = test.new(:test_0002_anonymous)
    failures = test_2.()
    assert_equal failures.size, 0

    test_3 = test.new(:test_0003_anonymous)
    failures = test_3.()
    assert_equal failures.size, 0
    assert_equal test_3.instance_variable_get(:@_m), %([:params, :model])

    test_4 = test.new(:test_0004_anonymous)
    failures = test_4.()
    assert_equal failures.size, 1
    assert_equal failures[0].inspect, %(#<Minitest::Assertion: --- expected
+++ actual
@@ -1 +1 @@
-AssertionsTest::Record(keyword_init: true)
+"Song"
>)

    test_5 = test.new(:test_0005_anonymous)
    failures = test_5.()
    assert_equal failures.size, 0

    test_6 = test.new(:test_0006_anonymous)
    failures = test_6.()
    assert_equal failures.size, 0

    test_7 = test.new(:test_0007_anonymous)
    failures = test_7.()
    assert_equal failures.size, 0

    test_8 = test.new(:test_0008_anonymous)
    failures = test_8.()
    assert_equal failures.size, 0
  end

          # include Trailblazer::Test::Assertion
  it "#assert_fail" do
        # assert_fail Update, {params: {bla: 1}}, [:title]
        # assert_fail Update, {params: {bla: 1}} do |result|
        # end

    test =
      Class.new(Test) do
        include Trailblazer::Test::Assertion

        # test_0001_anonymous
        it do
          assert_fail Update, {params: {title: nil}},
            # expected:
            [:title]
        end

        # test_0002_anonymous
        it do
          assert_fail Update, {params: {title: nil}},
            # expected:
            {title: ["is missing"]}
        end

        # test_0003_anonymous
        it do
          assert_fail Update, {params: {record: true}}, [:title]
        end

        # test_0004_anonymous
        it do
          assert_fail Update, {params: {title: nil}},
            # expected:
            {title: ["is XXX"]} # this is wrong.
        end

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
  Record = AssertionsTest::Record

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

  include Trailblazer::Test::Assertion
  include Trailblazer::Test::Assertion::Activity::Assert
  include Trailblazer::Test::Assertion::AssertExposes

  it do
    assert_pass Create, {params: {title: "Roxanne"}},
      title: "Roxanne"
  end

  it do
    assert_fail Create, {params: {}}, [:title]
  end
end

# Test with the Assertion::Suite "DSL" module.
class AssertionActivitySuiteTest < Minitest::Spec
  Record = AssertionsTest::Record
  Create = AssertionActivityTest::Create

  include Trailblazer::Test::Assertion::Suite
  include Trailblazer::Test::Assertion::Activity::Assert
  include Trailblazer::Test::Assertion::AssertExposes

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
  Record = AssertionsTest::Record
  Create = AssertionActivityTest::Create

  include Trailblazer::Test::Assertion
  include Trailblazer::Test::Assertion::Activity::Assert
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

