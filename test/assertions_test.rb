require "test_helper"

class AssertionsTest < Minitest::Spec
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

    assert_equal [["Timebomb", "__Timebomb__", "Property [title] mismatch"], ["Rancid", "__Rancid__", "Property [band] mismatch"]], test.()
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

    assert_equal [["Timebomb", "__Timebomb__", "Property [title] mismatch"], [true, "Actual: \"__Rancid__\"."]], test.()
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

    assert_equal [["Timebomb", "__Timebomb__", "Property [title] mismatch"], ["Rancid", "__Rancid__", "Property [band] mismatch"]], test.()
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

    assert_equal [["Timebomb", "__Timebomb__", "Property [title] mismatch"], ["Rancid", "__Rancid__", "Property [band] mismatch"]], test.()
  end
end
