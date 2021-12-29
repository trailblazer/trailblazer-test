require "test_helper"

class ExposesUnitTest < Minitest::Spec
  include Trailblazer::Test::Assertions

  let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }

  it do
    skip "fails!"
    assert_exposes model, title: "Timebomb", band: "Rancid"
  end
end

class DocsExposeTest < Minitest::Spec
  it "what" do
    passed, matches, last_failed = Trailblazer::Test::Assertions::Assert.match_tuples({title: "Timebomb"}, {title: "__Timebomb__"}, reader: :[])
     # pp matches
    assert_equal false, passed
    assert_equal %{[:title, \"__Timebomb__\", \"Timebomb\", false, true, \"Property [title] mismatch\"]}, last_failed.inspect
  end

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
