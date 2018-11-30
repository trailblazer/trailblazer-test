require "test_helper"
require "trailblazer/test/deprecation/operation/assertions"

class CtxParamsTest < Minitest::Spec
  describe "TRB 2.1" do
    include Trailblazer::Test::Operation::Assertions

    describe "params with empty default_params" do
      let(:default_params) { {} }

      it { assert_equal params(title: "Ancora tu"), params: {title: "Ancora tu"} }
    end

    describe "params with default_params" do
      let(:default_params) { {artist: "Lucio Battisti"} }

      it { assert_equal params(title: "Ancora tu"), params: {title: "Ancora tu", artist: "Lucio Battisti"} }
      it { assert_equal params(artist: "NOFX"), params: {artist: "NOFX"} }
    end

    describe "ctx with empty default_params and default_options" do
      let(:default_params) { {} }
      let(:default_options) { {} }

      it { assert_equal ctx(title: "Ancora tu"), params: {title: "Ancora tu"} }
      it { assert_equal ctx({title: "Ancora tu"}, current_user: "me"), params: {title: "Ancora tu"}, current_user: "me" }
    end

    describe "ctx with default_params and default_options" do
      let(:default_params) { {artist: "Lucio Battisti"} }
      let(:default_options) { {current_user: "me"} }

      it { assert_equal ctx(title: "Ancora tu"), params: {title: "Ancora tu", artist: "Lucio Battisti"}, current_user: "me" }
      it do
        assert_equal ctx({artist: "NOFX", title: "Punk in Drublic"}, current_user: "you"),
                     params: {artist: "NOFX", title: "Punk in Drublic"}, current_user: "you"
      end
    end

    describe "deep_merge" do
      let(:default_params)  { {form: {artist: "The Chats"}} }
      let(:default_options) { {current_user: {fname: "name", lname: "surname"}} }

      it do
        assert_equal ctx({form: {artist: "Pennywise"}}, current_user: {fname: "myname"}),
                     params: {form: {artist: "Pennywise"}}, current_user: {fname: "myname", lname: "surname"}
      end

      it do
        assert_equal ctx({form: {title: "Smoko"}}, current_user: {fname: "myname"}, deep_merge: false),
                     params: {form: {title: "Smoko"}}, current_user: {fname: "myname"}
      end
    end
  end

  describe "TRB 2.0" do
    include Trailblazer::Test::Deprecation::Operation::Assertions

    describe "params with empty default_params" do
      let(:default_params) { {} }

      it { assert_equal params(title: "Ancora tu"), [{title: "Ancora tu"}, {}] }
    end

    describe "params with default_params" do
      let(:default_params) { {artist: "Lucio Battisti"} }

      it { assert_equal params(title: "Ancora tu"), [{title: "Ancora tu", artist: "Lucio Battisti"}, {}] }
      it { assert_equal params(artist: "NOFX"), [{artist: "NOFX"}, {}] }
    end

    describe "ctx with empty default_params and default_options" do
      let(:default_params) { {} }
      let(:default_options) { {} }

      it { assert_equal ctx(title: "Ancora tu"), [{title: "Ancora tu"}, {}] }
      it { assert_equal ctx({title: "Ancora tu"}, "current_user" => "me"), [{title: "Ancora tu"}, {"current_user" => "me"}] }
    end

    describe "ctx with default_params and default_options" do
      let(:default_params) { {artist: "Lucio Battisti"} }
      let(:default_options) { {"current_user" => "me"} }

      it { assert_equal ctx(title: "Ancora tu"), [{title: "Ancora tu", artist: "Lucio Battisti"}, {"current_user" => "me"}] }
      it do
        assert_equal ctx({artist: "NOFX", title: "Punk in Drublic"}, "current_user" => "you", some: "other"),
                     [{artist: "NOFX", title: "Punk in Drublic"}, {"current_user" => "you", some: "other"}]
      end
    end

    describe "deep_merge" do
      let(:default_params)  { {form: {artist: "The Chats"}} }
      let(:default_options) { {"current_user" => {fname: "name", lname: "surname"}} }

      it do
        assert_equal ctx({form: {artist: "Pennywise"}}, "current_user" => {fname: "myname"}),
                     [{form: {artist: "Pennywise"}}, "current_user" => {fname: "myname", lname: "surname"}]
      end

      it do
        assert_equal ctx({form: {title: "Smoko"}}, "current_user" => {fname: "myname"}, deep_merge: false),
                     [{form: {title: "Smoko"}}, "current_user" => {fname: "myname"}]
      end
    end
  end
end
