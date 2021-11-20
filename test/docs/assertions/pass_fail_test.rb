require "test_helper"

class DocsPassFailAssertionsTest < OperationSpec
  # include Trailblazer::Test::Assertions
  # include Trailblazer::Test::Operation::Assertions

  Song = Struct.new(:band, :title) do
    def save()
      @save = true
    end
  end

  module Song::Contract
    class Create < Reform::Form
      property :band
      property :title

      require "reform/form/dry"
      include Reform::Form::Dry
      validation do
        params do
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
      step Contract::Persist()
    end
  end


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
          assert_fail( {band: ""}, {band: "Millencolin"} ) do |result|
            @_m = result[:"contract.default"].errors.messages.inspect
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



test_4 = test.new(:test_0004_anonymous)
      failures = test_4.()

      failures[0].must_equal nil
      test_4.instance_variable_get(:@_m).must_equal %{#<struct DocsPassFailAssertionsTest::Song band=\"Millencolin\", title=\"Timebomb\">}

test_5 = test.new(:test_0005_anonymous)
      failures = test_5.()

      failures[0].must_equal nil
      test_5.instance_variable_get(:@_m).must_equal %{{:band=>[\"must be filled\"]}}
  end
end

  #:assert_pass end

  # #:assert_pass-with-ctx
  # describe "Update with sane data" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

  #   # just works
  #   it { assert_pass Update, ctx(title: "Ruby Soho"), title: "Ruby Soho" }
  #   # trimming works
  #   it { assert_pass Update, ctx(title: "  Ruby Soho "), title: "Ruby Soho" }
  # end
  # #:assert_pass-with-ctx end

  # #:assert_pass-block
  # describe "Update with sane data" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:expected_attrs) { {band: "Rancid", title: "Timebomb"} }

  #   it do
  #     assert_pass Update, ctx(title: " Ruby Soho"), {} do |result|
  #       assert_equal "Ruby Soho", result[:model].title
  #     end
  #   end
  # end
  # #:assert_pass-block end

  # #:assert_fail
  # describe "Update with invalid data" do
  #   let(:default_params) { {band: "Rancid"} }

  #   it { assert_fail Update, ctx(band: "Adolescents"), expected_errors: [:band] }
  # end
  # #:assert_fail end

  # #:assert_fail-block
  # describe "Update with invalid data" do
  #   let(:default_params) { {band: "Rancid"} }

  #   it do
  #     assert_fail Update, ctx(band: " Adolescents") do |result|
  #       assert_equal({band: ["must be Rancid"]}, result["contract.default"].errors.messages)
  #     end
  #   end
  # end
  # #:assert_fail-block end

  # include Trailblazer::Test::Operation::PolicyAssertions

  # #:policy_fail-block
  # describe "Update with failing policy" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

  #   it do
  #     assert_policy_fail Update, ctx({title: "Ruby Soho"}, current_user: not_allowed_user)
  #   end
  # end
  # #:policy_fail-block end

  # describe "Update failing with custom policy" do
  #   let(:default_params) { {band: "Rancid"} }
  #   let(:not_allowed_user) { Struct.new(:name).new("not_allowed") }

  #   it do
  #     #:policy_fail-custom-name
  #     assert_policy_fail CustomUpdate, ctx({title: "Ruby Soho"}, current_user: not_allowed_user), policy_name: "custom"
  #     #:policy_fail-custom-name end
  #   end
  # end
