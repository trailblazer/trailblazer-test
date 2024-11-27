require "test_helper"

class AssertionsTest < Minitest::Spec
  class Test < Minitest::Spec
    def call
      run
      @failures
    end

    # include Trailblazer::Test::Assertions
  end

  Create = Trailblazer::Test::Testing::Song::Operation::Create

  it do
    test =
      Class.new(Test) do
        include Trailblazer::Test::Assertion::AssertExposes
        # include Trailblazer::Test::Operation::Assertions

        # test_0001_anonymous
        it do
          record = Struct.new(:id, :persisted?).new(1, true)

          assert_exposes record,
            id: 1,
            persisted?: true
        end

        # test_0002_anonymous
        it do
          record = Struct.new(:id, :persisted?).new(1, true)

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
end
