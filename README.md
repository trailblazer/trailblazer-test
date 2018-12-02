# Trailblazer::Test

[![Build Status](https://travis-ci.org/trailblazer/trailblazer-test.svg)](https://travis-ci.org/trailblazer/trailblazer-test)
[![Gem Version](https://badge.fury.io/rb/trailblazer-test.svg)](http://badge.fury.io/rb/trailblazer-test)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trailblazer-test'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trailblazer-test

## Usage

Add in your test `_helper` the following modules:

```ruby
include Trailblazer::Test::Assertions
include Trailblazer::Test::Operation::Assertions
```

If you are using Trailblazer v2.0 you need to add also:

```ruby
require "trailblazer/test/deprecation/operation/assertions"

include Trailblazer::Test::Deprecation::Operation::Assertions # in your test class
```

To be able to test an operation we need 3 auxiliary methods which have to be defined at the start of your tests:
* `default_params` (**required**): hash of params which will be always passed to the operation unless overriden by `params` or `ctx`
* `expected_attrs` (**required**): hash always used to assert model attributes
* `default_options` (**required if using `ctx`**): hash of options which will be always passed to the operation unless overriden by `ctx`

We are also providing 2 helper methods:
* `params(new_params)`
* `ctx(new_params, options)`

Those will merge params and options for you and return the final inputs which then can be passed to the operation under testing.

Pass `deep_merge: false` to the helper methods to disable the default deep merging of params and options.

*Same API for Trailblazer v2.0 and v2.1.*

Finally, using the built-in assertions you are able to test your operations in a fast and easy way:
* `assert_pass` -> your operation is successful and model has the correct attributes
* `assert_fail` -> your operation fails and returns some specific errors
* `assert_policy_fail` -> your operation fails because policy fails

#### params

`params` accepts one argument which is merged into `default_params`.

```ruby
let(:default_params) { { title: 'My title' } }

params(artist: 'My Artist') -> { params: { title: 'My title', artist: 'My Artist' } }
params(title: 'Other one') -> { params: { title: 'Other one' } }
```

#### ctx

`ctx` accepts 2 arguments, first one will be merged into the `default_params` and the second one will be merged into `default_options`

```ruby
let(:default_params)  { { title: 'My title' } }
let(:default_options) { { current_user: 'me' } }

ctx(artist: 'My Artist') -> { params: { title: 'My title', artist: 'My Artist' }, current_user: 'me' }
ctx({title: 'Other one'}, current_user: 'you') -> { params: { title: 'Other one' }, current_user: 'you' }
```

### assert_pass

```ruby
assert_pass(operation, ctx, expected_attributes)
```

Example:
```ruby
let(:default_params) { { band: 'The Chats'} }
let(:default_options) { { current_user: user} }
let(:expected_attrs) { { band: 'The Chats'} }

it { assert_pass MyOp, ctx(title: 'Smoko'), title: 'Smoko' }
```

Pass `deep_merge: false` to disable the deep merging of the third argument `expected_attributes` and the auxiliary method `expected_attrs`.

It's also possible to test in a more detailed way using a block:

```ruby
assert_pass MyOp, ctx(title: 'Smoko'), {} do |result|
  assert_equal "Smoko", result[:model].title
end
```

### assert_fail

```ruby
assert_fail(operation, ctx)
```

Example:
```ruby
let(:default_params) { { band: 'The Chats'} }
let(:default_options) { { current_user: user} }
let(:expected_attrs) { { band: 'The Chats'} }

it { assert_fail MyOp, ctx(title: 'Smoko') }
```

This will just test that the operation fails instead passing `expected_errors` as an array of symbols will also test that specific attribute has an error:

```ruby
assert_fail MyOp, ctx(band: 'Justing Beaver'), expected_errors: [:band] # definitely wrong!!!!
```

Using the block here will allow to test the error message:

```ruby
assert_fail MyOp, ctx(band: 'Justing Beaver') do |result|
  assert_equal 'You cannot listen Justing Beaver', result['contract.default'].errors.messages[:band]
end
```

Change contract name using `contract_name`.

*We will improve this part and allowing to the test message directly without using a block*


### assert_policy_fail

Add this in your test file to be able to use it:
```ruby
include Trailblazer::Test::Operation::PolicyAssertions
```

```ruby
assert_policy_fail(operation, ctx)
```

This will test that the operation fails due to a policy failure.

Example:
```ruby
let(:default_params) { { band: 'The Chats'} }
let(:default_options) { { current_user: user} }

it { assert_policy_fail MyOp, ctx({title: 'Smoko'}, current_user: another) }
```
Change policy name using `policy_name`.

## Test Setup

It is obviously crucial to test your operation in the correct test enviroment calling operation instead of using `FactoryBot` or simply `Model.create`.

To do so we provide 2 helper methods:
* `call`: will call the operation and **will not raise** an error in case of failure
* `factory`: will call the operation and **will raise** an error in case of failure returning also the trace and a validate error message in case exists

### Usage

Add this in your test `_helper.rb`:

```ruby
include Trailblazer::Test::Operation::Helper
```

In case you use are Trailblazer v2.0, you need to add this instead:

```ruby
require "trailblazer/test/deprecation/operation/helper"

include Trailblazer::Test::Deprecation::Operation::Helper
```

*Same API for both Trailblazer v2.0 and v2.1*

Examples:
```ruby
# call
let(:user) { call(User::Create, params: params)[:model] }

# call with block
let(:user) do
  call User::Create, params: params do |result|
    # run some code to reproduce some async jobs (for example)
  end[:model]
end

# factory - this will raise an error if User::Create fails
let(:user) { factory(User::Create, params: params)[:model] }

# factory - this will raise an error if User::Create fails
let(:user) do
  factory User::Create, params: params do |result|
    # this block will be yield only if User::Create is successful
    # run some code to reproduce some async jobs (for example)
  end[:model]
end
```
