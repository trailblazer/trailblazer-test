require "test_helper"

class AssertionsTest < Minitest::Spec
  class Test < Minitest::Spec
    def initialize(*)
      super
      @_assertions = []
    end

    def assert_equal(a, b, msg)
      @_assertions << [a, b]
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
      Class.new(Test) do
        let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }

        #:exp-eq
        it do
          assert_exposes model, title: "Timebomb", band:  "Rancid"
        end
        #:exp-eq end
      end.
      new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [["Timebomb", "__Timebomb__"], ["Rancid", "__Rancid__"]], test.()
  end

  it do
    test =
      Class.new(Test) do
        let(:model) { Struct.new(:title, :band).new("__Timebomb__", "__Rancid__") }

        #:exp-proc
        it do
          assert_exposes model,
            title: "Timebomb",
            band:  ->(actual) { actual.size > 3 }
        end
        #:exp-proc end
      end.
      new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [["Timebomb", "__Timebomb__"], [true, "Actual: \"__Rancid__\"."]], test.()
  end

  class Song
    def title; "__Timebomb__" end
    def band;  "__Rancid__" end
  end

  it do
    test =
      Class.new(Test) do
        let(:model) { Song.new }

        #:exp-reader-false
        it do
          assert_exposes model, { title: "Timebomb", band:  "Rancid" }, reader: false
        end
        #:exp-reader-false end
      end.
      new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [["Timebomb", "__Timebomb__"], ["Rancid", "__Rancid__"]], test.()
  end

  it do
    test =
      Class.new(Test) do
        class Song
          def get(name); name == :title ? "__Timebomb__": "__Rancid__" end
        end

        let(:model) { Song.new }

        #:exp-reader-get
        it do
          assert_exposes model, { title: "Timebomb", band:  "Rancid" }, reader: :get
        end
        #:exp-reader-get end
      end.
      new(:test_0001_anonymous) # Note: this has to be that name, otherwise the test case won't be run!

    assert_equal [["Timebomb", "__Timebomb__"], ["Rancid", "__Rancid__"]], test.()
  end
end
