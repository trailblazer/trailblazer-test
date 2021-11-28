require "bundler/setup"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/test"

require "minitest/autorun"

require "trailblazer/macro"
require "trailblazer/macro/contract"
# require "reform/form/active_model/validations" # FIXME: document!
require "dry-validation" #  FIXME: bug in reform-rails with Rails 6.1 errors object forces us to use dry-v until it's fixed.
require "trailblazer/operation"

require "trailblazer/activity/testing"

Activity  = Trailblazer::Activity
Testing   = Trailblazer::Activity::Testing


