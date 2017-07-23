require "test_helper"

class AssertionsTest < Minitest::Spec
  class Test < Minitest::Spec
    def initialize(*)
      super
      @_assertions = []
    end

    def assert_equal(a, b)
      @_assertions << [a, b]
    end

    def call
      run
      @_assertions
    end

    include Trailblazer::Test::Assertions
  end


  it do
    test =
      Class.new(Test) do
        it do
          assert_exposes( { a:1, b:2, c:3 }, a: 11, b: 22)
        end
      end.
      new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [[1, 11], [2, 22]], test.()
  end
end
