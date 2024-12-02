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

        include Trailblazer::Test::Assertion::AssertPass
  it "#assert_pass" do
        # assert_pass Create, {params: {bla: 1}}, id: 1

    test =
      Class.new(Test) do
        include Trailblazer::Test::Assertion::AssertPass
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
      end

    test_1 = test.new(:test_0001_anonymous)
    failures = test_1.()
    assert_equal failures.size, 1
    failures[0].inspect.must_equal %(#<Minitest::Assertion: Property [id] mismatch.
Expected: 1
  Actual: nil>)
  end
end
