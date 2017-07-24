require "test_helper"

class HelperTest < Minitest::Spec
  Result    = Struct.new(:input, :success) do
    def success?; self.success; end
  end
  Operation = ->(*args) { Result.new( args, true ) }
  FailingOperation = ->(*args) { Result.new( args, false ) }

  class Test < Minitest::Spec
    include Trailblazer::Test::Helper::Operation

    it do
      result = call HelperTest::Operation, {}
    end

    it do
      call HelperTest::Operation, { a: 1 }, { b: 2}
    end

    it do
      model = factory( HelperTest::Operation, {} )
    end

    it do
      assert_raises Trailblazer::Test::OperationFailedError do
        factory( HelperTest::FailingOperation, {} )
      end
    end
  end

  it { assert_equal [{}], Test.new(:a).test_0001_anonymous.input }
  it { assert_equal [{:a=>1}, {:b=>2}], Test.new(:a).test_0002_anonymous.input }

  # returns result.
  it { assert_equal %{#<struct HelperTest::Result input=[], success=true>}, Test.new(:a).test_0003_anonymous.inspect }
  # raises error
  it { assert_instance_of Trailblazer::Test::OperationFailedError, Test.new(:a).test_0004_anonymous }
end
