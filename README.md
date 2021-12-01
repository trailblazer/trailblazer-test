# Trailblazer::Test

Testing a Trailblazer project is very simple. Your test suite usually consists of two separate layers.

* Integration tests or system tests covering the full stack, and using Capybara to “click through” the happy path and possible edge-cases such as an erroring form. Smoke tests make sure of the integrity of your application, and assert that controllers, views and operations play well together. We will provide more documentation about system tests shortly.
* Operation unit tests guarantee that your operations, data processing and validations do what they’re supposed to. As they’re much faster and easier to write than full stack “smoke tests” they can cover any possible input to your operation and help quickly asserting the created side-effects. The trailblazer-test gem is here to help with that.

There’s no need to test controllers, models, service objects, etc. in isolation - unless you want to do so for a better documentation of your internal APIs. As operations are the single entry-point for your functions, your entire stack is covered with the two test types.

The trailblazer-test gem allows simple, streamlined operation unit tests. If you fancy RSpec, [rspec-trailblazer-test](https://github.com/trailblazer/rspec-trailblazer-test/) is here for you.

## Documentation

The TRB website has [extensive documentation on this gem](https://trailblazer.to/2.1/docs/test.html).

## Overview

For operation unit tests, this gem provides `assert_pass` and `assert_fail`.

```ruby
# test/operation/song_operation_test.rb
class SongOperationTest < OperationSpec

  # The default ctx passed into the tested operation.
  let(:default_ctx) do
    {
      params: {
        song: { # Note the {song} key here!
          band:  "Rancid",
          title: "Timebomb",
          # duration not present
        }
      }
    }
  end

  # What will the model look like after running the operation?
  let(:expected_attributes) do
    {
      band:   "Rancid",
      title:  "Timebomb",
    }
  end

  let(:operation)     { Song::Operation::Create }
  let(:key_in_params) { :song }

  it "passes with valid input, {duration} is optional" do
    assert_pass( {}, {} )
  end

  it "converts {duration} to seconds" do
    assert_pass( {duration: "2.24"}, {duration: 144} )
  end

  it "converts {duration} to seconds" do
    assert_pass( {duration: "2.24"}, {duration: 144} ) do |result|
      assert_equal true, result[:model].persisted?
    end
  end

  it "fails with missing {title} and invalid {duration}" do
    assert_fail( {duration: 1222, title: ""}, [:title, :duration] )
  end
  # ...
end
```
