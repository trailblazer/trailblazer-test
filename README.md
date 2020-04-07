# Trailblazer::Test

[![Build Status](https://travis-ci.org/trailblazer/trailblazer-test.svg)](https://travis-ci.org/trailblazer/trailblazer-test)
[![Gem Version](https://badge.fury.io/rb/trailblazer-test.svg)](http://badge.fury.io/rb/trailblazer-test)

## Usage

Testing Trailblazer applications usually involves the following tests.

1. **Unit tests for operations**: They test all edge cases in a nice, fast unit test environment without any HTTP involved.
2. **Integration tests for controllers**: These Smoke tests only test the wiring between controller, operation and presentation   layer. Usually, a coded click path simulates you manually clicking through your app and testing if it works. The preferred way    here is using Rack-test and Capybara.
3. **Unit tests for cells** By invoking your cells with arbitrary data you functionally test the rendered markup using Capybara.

All the up to date details on the available assertions and helpers is available at [official documentation](http://2019.trailblazer.to/2.1/docs/trailblazer.html#trailblazer-test).

### Assertions

To use available assertions, add in your test `_helper` the following modules:

```ruby
include Trailblazer::Test::Assertions
include Trailblazer::Test::Operation::Assertions
```

If you are using Trailblazer v2.0 you need to add also:

```ruby
require "trailblazer/test/deprecation/operation/assertions"

include Trailblazer::Test::Deprecation::Operation::Assertions # in your test class
```

[Learn more](http://2019.trailblazer.to/2.1/docs/trailblazer.html#trailblazer-test-assertions)

#### assert_pass

Use `assert_pass` to run an operation and assert it was successful, while checking if the attributes of the operation's `model` are what you're expecting.

```ruby
it { assert_pass Blog::Operation::Create, { params: { title: "Ruby Soho" } }, title: "Ruby Soho" }
```

#### assert_fail

To test an unsuccessful outcome of an operation, use `assert_fail`. This is used for testing all kinds of validations. By passing insufficient or wrong data to the operation, it will fail and mark errors on the errors object.

```ruby
it { assert_fail Blog::Operation::Update, { params: { band: nil } }, expected_errors: [:band] }
```

#### assert_policy_fail

This will test that the operation fails due to a policy failure.

```ruby
it { assert_policy_fail Blog::Operation::Delete, ctx({title: "Ruby Soho"}, current_user: not_allowed_user) }
```

#### assert_exposes

Test attributes of an arbitrary object.

```ruby
it { assert_exposes model, title: "Timebomb", band: "Rancid" }
```

### Helpers

There are several helpers to deal with operation tests and operations used as factories.
Add this in your `_helper.rb` file to use all available helpers.

```ruby
include Trailblazer::Test::Operation::Helper
```

[Learn more](http://2019.trailblazer.to/2.1/docs/trailblazer.html#trailblazer-test-helpers)

#### call

Instead of manually invoking an operation, you can use the `call` helper.

```ruby
it do
  result = call Blog::Operation::Create, params: {title: "Shipwreck", band: "Rancid"}
  # use `result` object however you want
end
```

#### factory

The `factory` method calls the operation and raises an error should the operation have failed. If successful, it will do the exact same thing `call` does.

```ruby
it do
  assert_raises do
    factory Blog::Operation::Create, params: {title: "Shipwreck", band: "The Chats"}
  end
end
```

#### mock_step

This helper allows you to mock any step within a given or deeply nested activities. For example,

```ruby
class Show < Trailblazer::Operation
  step :load_user
  ...
end
```

To skip processing inside `:load_user` and use a mock instead, use `mock_step`.

```ruby
it do
  new_activity = mock_step(Show, id: :load_user) do |ctx|
    ctx[:user] = Struct.new(:name).new('Mocky')
  end

  assert_pass new_activity, {}, {} do |ctx|
    assert_equal ctx[:user].name, 'Mocky'
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trailblazer-test'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trailblazer-test
