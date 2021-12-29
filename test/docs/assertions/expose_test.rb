require "test_helper"

class ExposesUnitTest < Minitest::Spec
  include Trailblazer::Test::Assertions

  let(:ass) { Trailblazer::Test::Assertions::Assert }

  let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }


  describe "{Assert.expected_attributes_for}" do
    it "what" do
      expected = Trailblazer::Test::Operation::Assertions::Assert.expected_attributes_for({title: "Timebomb", class: Object},
        expected_attributes: {title: "The Brews", duration: 999},
        deep_merge: false,
      )
      pp expected
    end
  end

  it do
    skip "fails!"
    assert_exposes model, title: "Timebomb", band: "Rancid"
  end

  it "runs block when match fails" do
    passed, matches, last_failed = ass.assert_attributes({title: "Timebomb"}, {title: "__Timebomb__"}, reader: :[]) do |matches, last_failed|
      @block_run = last_failed
    end
     # pp matches
    assert_equal false, passed
    assert_equal %{[:title, \"__Timebomb__\", \"Timebomb\", false, true, \"Property [title] mismatch\"]}, last_failed.inspect
    assert_equal %{[:title, "__Timebomb__", "Timebomb", false, true, "Property [title] mismatch"]}, @block_run.inspect
  end

  it "all properties match" do
    passed, matches, last_failed = ass.assert_attributes(model, {title: "__Timebomb__", band: "__Rancid__"}) do |*|
      @block_run = true
    end

    assert_equal true, passed
    assert_nil @block_run
  end
end

class DocsExposeTest < Minitest::Spec

  class Test < Minitest::Spec
    def initialize(*)
      super
      @_assertions = []
    end

    def assert_equal(a, b, msg)
      @_assertions << [a, b, msg]
    end

    def assert(a, msg)
      @_assertions << [a, msg]
      # super
    end

    def call
      run
      puts self.inspect
      @_assertions
    end

    include Trailblazer::Test::Assertions
  end

  it do
    test =
      Class.new(Test) {
        let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }

        #:exp-eq
        it do
          assert_exposes model, title: "Timebomb", band: "Rancid"
        end
        #:exp-eq end
      }.new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [
      ["Timebomb", "__Timebomb__", "Property [title] mismatch"],
      # ["Rancid", "__Rancid__", "Property [band] mismatch"]
    ], test.()
  end

  class Song
    def title;
      "__Timebomb__"
    end

    def band;
      "__Rancid__"
    end
  end

  it do
    test =
      Class.new(Test) {
        let(:model) { Song.new }

        #:exp-proc
        it do
          assert_exposes model, title: "Timebomb", band: ->(actual:, **) { actual.size > 3 }
        end
        #:exp-proc end
      }.new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [["Timebomb", "__Timebomb__", "Property [title] mismatch"],
      #[true, "Actual: \"__Rancid__\"."]
    ], test.()
  end

  # error message for {assert} case.
  it do
    test =
      Class.new(Test) {
        let(:model) { Song.new }

        it do
          assert_exposes model, band: ->(actual:, **) { actual.size > 3 }, title: "Timebomb"
        end
      }.new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [
      [true, "Actual: \"__Rancid__\"."]], test.()
      # ["Timebomb", "__Timebomb__", "Property [title] mismatch"],

  end

  # reader: :[]
  it do
    test =
      Class.new(Test) {
        let(:model) { {title: "__Timebomb__", band: "__Rancid__"} }

        #:exp-reader-hash
        it do
          assert_exposes model, {title: "Timebomb", band: "Rancid"}, reader: :[]
        end
        #:exp-reader-hash end
      }.new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [
      ["Timebomb", "__Timebomb__", "Property [title] mismatch"],
      ["Rancid", "__Rancid__", "Property [band] mismatch"]
    ], test.()
  end

  it do
    test =
      Class.new(Test) {
        class Song
          def get(name);
            name == :title ? "__Timebomb__" : "__Rancid__"
          end
        end

        let(:model) { Song.new }

        #:exp-reader-get
        it do
          assert_exposes model, {title: "Timebomb", band: "Rancid"}, reader: :get
        end
        #:exp-reader-get end
      }.new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [
      ["Timebomb", "__Timebomb__", "Property [title] mismatch"],
      ["Rancid", "__Rancid__", "Property [band] mismatch"]
    ], test.()
  end
end
