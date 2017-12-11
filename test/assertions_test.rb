require "test_helper"

class AssertionsTest < Minitest::Spec
  include Trailblazer::Test::Assertions

  it do
    model = Struct.new(:title, :band).new("__Timebomb__", "__Rancid__")

    expect {
      assert_exposes model, title: "Timebomb", band: "Rancid"
    }.to raise_error(a_string_including 'expected #<struct title="__Timebomb__", band="__Rancid__"> to have attributes')
  end

  class Song
    def title; "__Timebomb__" end
    def band;  "__Rancid__" end
  end

  it do
    model = Song.new

    expect {
      assert_exposes model,
        title: "Timebomb",
        band:  ->(actual) { actual.size > 3 }
    }.to raise_error(a_string_including '-:title => "Timebomb"', '+:title => "__Timebomb__"')
  end
end
