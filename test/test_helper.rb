require "bundler/setup"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/test"

require "minitest/autorun"

require "trailblazer/operation"
require "trailblazer/activity/testing"
require "trailblazer/test"
require "trailblazer/test/testing" # {Song} and {Song::Operation::Create} etc
require "trailblazer/core"

Activity  = Trailblazer::Activity
Testing   = Trailblazer::Activity::Testing
CU = Trailblazer::Core::Utils
