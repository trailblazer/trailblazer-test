require "test_helper"

class AssertExposesTest < Minitest::Spec
  # TODO: should we test the "meat" of these assertions here?
  it "#assert_exposes" do
    test =
      Class.new(Test) do
        include Trailblazer::Test::Assertion::AssertExposes
        Memo = Trailblazer::Test::Testing::Memo

        # 01
        it do
          memo = Memo.new(title: "TODO", id: 1)

          assert_exposes memo,
            id: 1,
            title: "TODO"

          @result = {}
        end

        # 02
        # fails
        it do
          memo = Memo.new(title: "TODO", id: 1)

          assert_exposes memo,
            title: "TODO",
            content: "this is wrong"
        end
      end

    assert_test_case_passes(test, "01", nil)
    assert_test_case_fails(test, "02", %(#<Minitest::Assertion: Property [content] mismatch.
Expected: "this is wrong"
  Actual: nil>))
  end
end
