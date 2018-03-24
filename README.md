# Trailblazer::Test

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/trailblazer/test`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

### `default_params`, `default_options` and `expected_attrs`

* `default_params` - **required**: hash of params which will be always passed to the operation unless overriden by `params` or `ctx`
* `expected_attrs` - **required**: hash always used to assert model attributes
* `default_options` - **required if using `ctx`**: hash of options which will be always passed to the operation unless overriden by `ctx`

### `ctx` and `params`

They can be used to pass inputs to the operation under testing. `params` is used when operation does not have any options to pass instead `ctx` is used when operation needs params and options as inputs.

Same API for TRB 2.0 and TRB 2.1 (just make sure to pass the correct format symbol/string - no magic applied here!).

The only different between 2.0 and 2.1 that params is nested into `params:` for 2.1 automatically.

Use the key `deep_merge` to disable the default deep_merging of params and options.

#### `params`

`params` accepts one argument which is merged into `default_params`.

Example (TRB 2.1):

```
let(:default_params) { { title: 'My title' } }

params(artist: 'My Artist') -> { params: { title: 'My title', artist: 'My Artist' } }
params(title: 'Other one') -> { params: { title: 'Other one' } }
```

#### `ctx`

`ctx` accepts 2 arguments, first one will be merged into the `params` and the second one will be merged into `default_options`

Example (TRB 2.1):

```
let(:default_params)  { { title: 'My title' } }
let(:default_options) { { current_user: 'me' } }

ctx(artist: 'My Artist') -> { params: { title: 'My title', artist: 'My Artist' }, current_user: 'me' }
ctx({title: 'Other one'}, current_user: 'you') -> { params: { title: 'Other one' }, current_user: 'you' }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/trailblazer-test.
