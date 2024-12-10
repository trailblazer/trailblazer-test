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
# assert_pass Create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond", invoke_method: :wtf?

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
            assert_pass Create, {params: {title: "Somewhere Far Beyond"}}, title: "Somewhere Far Beyond", invoke_method: :wtf?
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
  end

          include Trailblazer::Test::Assertion
  it "#assert_fail" do
        assert_fail Update, {params: {bla: 1}}, [:title]
        # assert_fail Update, {params: {bla: 1}} do |result|
        # end

    test =
      Class.new(Test) do
        include Trailblazer::Test::Assertion
        # include Trailblazer::Test::Assertion::AssertExposes

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
            assert_fail Update, {params: {title: nil}}, [:title], invoke_method: :wtf?
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
  end
end
