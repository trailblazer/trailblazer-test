require "test_helper"
#:operation-spec
# test/test_helper.rb
# ...

class OperationSpec < Minitest::Spec
  include Trailblazer::Test::Assertions
  include Trailblazer::Test::Operation::Assertions
end
#:operation-spec end

class DocsPassFailAssertionsTest < OperationSpec
  # include Trailblazer::Test::Assertions
  # include Trailblazer::Test::Operation::Assertions

  Song = Struct.new(:band, :title, :duration) do
    def save()
      @save = true
    end

    def persisted?
      !! @save
    end
  end

  module Song::Contract
    class Create < Reform::Form
      property :band
      property :title
      property :duration

      require "reform/form/dry"
      include Reform::Form::Dry
      validation do
        params do
          required(:title).filled
          optional(:duration).maybe(type?: String)
          required(:band).filled
        end
      end
      # validates :band, presence: true
    end
  end


  module Song::Operation
    class Create < Trailblazer::Operation
      step Model(Song, :new)
      step Contract::Build(constant: Song::Contract::Create)
      step Contract::Validate(key: :song)
      step :parse_duration
      step Contract::Persist()

      def parse_duration(ctx, **)
        duration = ctx["contract.default"].duration or return true

        m = duration.match(/(\d)\.(\d\d)$/)
        duration_seconds = m[1].to_i*60 + m[2].to_i

        ctx["contract.default"].duration = duration_seconds
      end
    end
  end


  #:test
  # test/operation/song_operation_test.rb
  class SongOperationTest < OperationSpec

    # The default ctx passed into the tested operation.
    #:default-ctx
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
    #:default-ctx end

    #:expected-attrs
    # What will the model look like after running the operation?
    let(:expected_attrs) do
      {
        band:   "Rancid",
        title:  "Timebomb",
      }
    end
    #:expected-attrs end

    #:let-operation
    let(:operation)     { Song::Operation::Create }
    #:let-operation end
    #:let-key-in-params
    let(:key_in_params) { :song }
    #:let-key-in-params end

    #:assert-pass-empty
    it "passes with valid input, {duration} is optional" do
      assert_pass( {}, {} )
    end
    #:assert-pass-empty end

    #:assert-pass
    it "converts {duration} to seconds" do
      assert_pass( {duration: "2.24"}, {duration: 144} )
    end
    #:assert-pass end

    #:assert-pass-block
    it "converts {duration} to seconds" do
      assert_pass( {duration: "2.24"}, {duration: 144} ) do |result|
        assert_equal true, result[:model].persisted?
      end
    end
    #:assert-pass-block end

    #:assert-fail
    it "fails with missing {title} and invalid {duration}" do
      assert_fail( {duration: 1222, title: ""}, [:title, :duration] )
    end
    #:assert-fail end
    #~meths
    #:assert-fail-block
    it "fails with missing {title} and invalid {duration}" do
      assert_fail( {duration: 1222, title: ""}, [:title, :duration] ) do |result|
        assert_equal false, result[:model].persisted?
        assert_equal 2,     result[:"contract.default"].errors.size
      end
    end
    #:assert-fail-block end

    #:wtf
    it "fails with missing {title} and invalid {duration}" do
      assert_fail( {duration: 1222, title: ""}, [:title, :duration], :wtf? )
      #=>
      # -- Song::Operation::Create
      # |-- Start.default
      # |-- model.build
      # |-- contract.build
      # |-- contract.default.validate
      # |   |-- Start.default
      # |   |-- contract.default.params_extract
      # |   |-- contract.default.call
      # |   `-- End.failure
      # `-- End.failure
    end
    #:wtf end
    #~meths end
  end
  #:test end

  # No {key: :song}.
  class SongOperation_OMIT_KEY_Test < OperationSpec
    module Song; end

    module Song::Operation
      class Create < Trailblazer::Operation
        step Model(DocsPassFailAssertionsTest::Song, :new)
        step Contract::Build(constant: DocsPassFailAssertionsTest::Song::Contract::Create)
        step Contract::Validate()
        step Contract::Persist()
      end
    end
    let(:operation) { Song::Operation::Create }
    let(:expected_attrs) do
      {
        band:   "Rancid",
        title:  "Timebomb",
      }
    end

    #:let-key-in-params-false
    let(:key_in_params) { false }

    let(:default_ctx) do
      {
        params: {
          band:  "Rancid",
          title: "Timebomb",
        }
      }
    end
    #:let-key-in-params-false end


    it "passes with valid input, {duration} is optional" do
      assert_pass( {}, {} )
    end

    #:omit-key-it
    it "sets {title}" do
      assert_pass( {title: "Ruby Soho"}, {title: "Ruby Soho"} )
    end
    #:omit-key-it end

    it "fails with missing {title} and invalid {duration}" do
      assert_fail( {title: ""}, [:title] )
    end
  end # SongOperation_OMIT_KEY_Test

  # module Song::Operation
  #   class Create < Trailblazer::Operation
  #     step Model(Song, :new)
  #     step Contract::Build(constant: Song::Contract::Create)
  #     step Contract::Validate(key: :song)
  #     step Contract::Persist()
  #   end
  # end


  #:assert_pass
  describe "Create with sane data" do
    # What are we passing into the operation?
    let(:default_ctx) do
      {
        params: {
          song: { # Note the {song} key here!
            band:  "Rancid",
            title: "Timebomb",
          }
        }
      }
    end

    # What will the model look like after running the operation?
    let(:expected_attrs) do
      {
        band:   "Rancid",
        title:  "Timebomb",
      }
    end

    let(:operation)     { Song::Operation::Create }
    let(:key_in_params) { :song }

    # valid default input, works
    it { assert_pass( {}, {} ) }

    # Check if {:title} can be overridden
    it { assert_pass( {title: "Ruby Soho"}, {title: "Ruby Soho"} ) }
    # Assert if automatic trimming works...
    # Check if coercing works..

    # Check if validations work
    it { assert_fail( {band: ""}, [:band], :wtf? ) }

    # it { assert_fail( {band: ""}, [:band], :wtf? ) }

    it do
      assert_pass( {title: "Ruby Soho"}, {title: "Ruby Soho"} ) do |result|
        assert_equal "Rancid", result[:model].band
      end
    end

    it do
      assert_fail( {band: ""}, {title: "Ruby Soho"} ) do |result|
        assert_equal nil, result[:model].band
        # puts result[:"contract.default"].errors.messages # Yes, this is good for debugging!
      end
    end

    # Ctx(exclude: [])
    it do
      # {:band} is still set:
      assert_pass( Ctx(exclude: [:title]), {title: nil} )
      # {:band} is missing
      assert_fail( Ctx(exclude: [:band]),  [:band]) do |result|
        assert_equal "Timebomb", result[:"contract.default"].title # title is still set from {default_ctx}!
      end
    end
  end

  class Test < Minitest::Spec
    def call
      run
      @failures
    end

    include Trailblazer::Test::Assertions
  end

  it "gives colored error messages for {assert_pass} and {assert_fail}" do
    test =
      Class.new(Test) {
        include Trailblazer::Test::Assertions
        include Trailblazer::Test::Operation::Assertions

        # What are we passing into the operation?
        let(:default_ctx) do
          {
            params: {
              song: { # Note the {song} key here!
                band:  "Rancid",
                title: "Timebomb",
              }
            }
          }
        end

        # What will the model look like after running the operation?
        let(:expected_attrs) do
          {
            band:   "Rancid",
            title:  "Timebomb",
          }
        end

        let(:operation)     { DocsPassFailAssertionsTest::Song::Operation::Create }
        let(:key_in_params) { :song }

        # Assertion fails since {:title} doesn't have errors set.
        it { assert_fail( {band: ""}, [:band, :title] ) }

        # Assertion fails because {title}s don't match.
        it { assert_pass( {title: "Ruby Soho"}, {title: "ruby soho"} ) }

        # Assertion fails because validation error.
        it { assert_pass( {band: ""}, {title: "Ruby Soho"} ) }

        # Test if block is called
        it do #4
          assert_pass( {band: "Millencolin"}, {band: "Millencolin"} ) do |result|
            @_m = result[:model].inspect
          end
        end

        it do #5
          assert_fail( {band: ""}, [:band] ) do |result|
            assert_nil result[:model].title
            @_m = result[:"contract.default"].errors.messages.inspect
          end
        end

        # Test: Block shouldn't be called when assertions before failed.
        it do #6
          assert_pass( {band: "Millencolin"}, {band: "NOFX"} ) do |result|
            @_m = result[:model].inspect
          end
        end
      }

      test_1 = test.new(:test_0001_anonymous)

      failures = test_1.()

      # {assert_fail} sees less errors than the user specified: The errors are colored.
      failures[0].inspect.must_equal %{#<Minitest::Assertion: Actual contract errors: \e[33m{:band=>["must be filled"]}\e[0m.
Expected: [:band, :title]
  Actual: [:band]>}

      assert_equal 1, failures.size





test_2 = test.new(:test_0002_anonymous)
      failures = test_2.()

      # {assert_pass} complains because {title} doesn't match
      failures[0].inspect.must_equal %{#<Minitest::Assertion: Property [title] mismatch.
Expected: "ruby soho"
  Actual: "Ruby Soho">}

      assert_equal 1, failures.size






test_3 = test.new(:test_0003_anonymous)
      failures = test_3.()

      # {assert_pass} complains because {title} doesn't match
      failures[0].inspect.must_equal %{#<Minitest::Assertion: {DocsPassFailAssertionsTest::Song::Operation::Create} failed: \e[33m{:band=>[\"must be filled\"]}\e[0m.
Expected: true
  Actual: false>}



# You can see {ctx[:"contract.default"]} in the {#assert_pass} block.
test_4 = test.new(:test_0004_anonymous)
      failures = test_4.()

      failures[0].must_equal nil
      test_4.instance_variable_get(:@_m).must_equal %{#<struct DocsPassFailAssertionsTest::Song band=\"Millencolin\", title=\"Timebomb\", duration=nil>}
      assert_equal 4, test_4.instance_variable_get(:@assertions)
# pass block is not run when assertion failed before
test_6 = test.new(:test_0006_anonymous)
      failures = test_6.()
      assert_equal 2, test_6.instance_variable_get(:@assertions)
      failures[0].inspect.must_equal %{#<Minitest::Assertion: Property [band] mismatch.
Expected: "NOFX"
  Actual: "Millencolin">}
      assert_nil test_6.instance_variable_get(:@_m) # no block called.

# You can see {ctx[:"contract.default"]} in the {#assert_fail} block.
test_5 = test.new(:test_0005_anonymous)
      failures = test_5.()

      assert_nil failures[0]
      test_5.instance_variable_get(:@_m).must_equal %{{:band=>[\"must be filled\"]}}
      assert_equal 4, test_5.instance_variable_get(:@assertions) # FIXME: why is this 4, not 3?

  end
end




  # include Trailblazer::Test::Operation::PolicyAssertions

  # #:policy_fail-block
  # describe "Update with failing policy" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

  #   it do
  #     assert_policy_fail Update, Ctx({title: "Ruby Soho"}, current_user: not_allowed_user)
  #   end
  # end
  # #:policy_fail-block end

  # describe "Update failing with custom policy" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

  #   it do
  #     #:policy_fail-custom-name
  #     assert_policy_fail CustomUpdate, Ctx({title: "Ruby Soho"}, current_user: not_allowed_user), policy_name: "custom"
  #     #:policy_fail-custom-name end
  #   end
  # end
