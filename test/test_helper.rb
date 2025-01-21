require "bundler/setup"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/test"

require "minitest/autorun"

require "trailblazer/operation"
require "trailblazer/activity/testing"
require "trailblazer/test"
require "trailblazer/test/testing" # {Song} and {Song::Operation::Create} etc
require "trailblazer/core"

Testing   = Trailblazer::Activity::Testing
CU = Trailblazer::Core::Utils

Minitest::Spec.class_eval do
  def assert_test_case_passes(test, number, input)
    test_case = test.new(:"test_00#{number}_anonymous")
    failures, assertions, result = test_case.()

    puts failures if failures.size > 0 # TODO: this is an automatic "debugger" :D
    assert_equal failures.size, 0
    # assert_equal assertions, assertion_count

    assert_equal result[:captured], input
  end

  def assert_test_case_fails(test, number, error_message)
    test_case = test.new(:"test_00#{number}_anonymous")
    failures, assertions, _ = test_case.()

    assert_equal failures.size, 1
    assert_equal failures[0].inspect, error_message
  end
end
