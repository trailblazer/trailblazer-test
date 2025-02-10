# Trailblazer::Test

_Assertions and helpers for operation unit tests._

The [comprehensive docs are here](https://trailblazer.to/2.1/docs/test/).

Read our introducing blog post for a better overview.

## Installation

Add the following line to your project's `Gemfile`.

```ruby
gem "trailblazer-test", ">= 1.0.0", "< 2.0.0"
```

## Overview

This gem adds the following assertions and helpers:

* `#assert_pass` to test an operation terminating with success.
* `#assert_fail` to assert validation errors and the like.
* `#mock_step` helping the replace steps with stubs.

## Example

An example test case checking if an operation passed and created a model could look as follows.

```ruby
# test/operation/memo_test.rb

require "test_helper"

class MemoOperationTest < Minitest::Spec
  Trailblazer::Test.module!(self) # install our helpers.

  it "passes with valid input" do
    # ...
    assert_pass Memo::Operation::Create, input,
      content:    "Stock up beer",
      persisted?: true,
      id:         ->(asserted:, **) { asserted.id > 0 }
  end
end
```
