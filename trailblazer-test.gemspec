lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trailblazer/test/version"

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-test"
  spec.version       = Trailblazer::Test::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]

  spec.summary       = "Assertions, matchers, and helpers to test Trailblazer code."
  spec.description   = "Assertions, matchers, and helpers to test Trailblazer code."
  spec.homepage      = "http://trailblazer.to"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r(^exe/)) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "hashie"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-line"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "trailblazer-operation"
  spec.add_development_dependency "trailblazer-macro"
  spec.add_development_dependency "trailblazer-macro-contract"
  # spec.add_development_dependency "reform-rails"
  spec.add_development_dependency "dry-validation"
  spec.add_development_dependency "trailblazer-core-utils", ">= 0.0.5"

  spec.add_dependency "trailblazer-activity-dsl-linear", ">= 1.2.6"
end
