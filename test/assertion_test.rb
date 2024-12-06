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
    failures[0].inspect.must_equal %(#<Minitest::Assertion: Property [id] mismatch.
Expected: 2
  Actual: 1>)
  end

        # include Trailblazer::Test::Assertion
        # include Trailblazer::Test::Assertion::AssertExposes
  it "#assert_pass" do
        # assert_pass Create, {params: {title: 1}}, id: 1
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
      end

    test_1 = test.new(:test_0001_anonymous)
    failures = test_1.()
    assert_equal failures.size, 1
    failures[0].inspect.must_equal %(#<Minitest::Assertion: Property [id] mismatch.
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
    failures[0].inspect.must_equal %(#<Minitest::Assertion: --- expected
+++ actual
@@ -1 +1 @@
-AssertionsTest::Record(keyword_init: true)
+"Song"
>)
  end

          include Trailblazer::Test::Assertion
  it "#assert_fail" do
        assert_fail Update, {params: {bla: 1}}, [:title]

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
    failures[0].inspect.must_equal %(#<Minitest::Assertion: {AssertionsTest::Update} didn't fail, it passed.
Expected: false
  Actual: true>)

  test_4 = test.new(:test_0004_anonymous)
    failures = test_4.()
    assert_equal failures.size, 1
    failures[0].inspect.must_equal %(#<Minitest::Assertion: Actual contract errors: \e[33m{:title=>[\"is missing\"]}\e[0m.
Expected: {:title=>[\"is XXX\"]}
  Actual: {:title=>[\"is missing\"]}>)
  end
end
