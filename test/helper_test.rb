require "test_helper"

class HelperTest < Minitest::Spec
  Result    = Struct.new(:input)
  Operation = ->(*args) { Result.new( args ) }

  class Test < Minitest::Spec
    include Trailblazer::Test::Helper::Operation

    it do
      @result = call HelperTest::Operation, {}
    end

    it do
      call HelperTest::Operation, { a: 1 }, { b: 2}
    end
  end

  test = Test.new(:a).test_0001_anonymous.input.must_equal [{}]
  test = Test.new(:a).test_0002_anonymous.input.must_equal [{:a=>1}, {:b=>2}]
end
