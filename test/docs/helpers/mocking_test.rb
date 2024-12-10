require "test_helper"

class DocsMockingTest < Minitest::Spec
  #:mock-show-operation
  class Show < Trailblazer::Operation
    class Complexity < Trailblazer::Operation
      class ExternalApi < Trailblazer::Operation
        step :make_call
        #~method
        include Testing.def_steps(:make_call)
        #~method end
      end

      step :some_complex_task
      step Subprocess(ExternalApi)
      #~method
      include Testing.def_steps(:some_complex_task)
      #~method end
    end

    step :load_user
    step Subprocess(Complexity)
    #~method
    include Testing.def_steps(:load_user)
    #~method end
  end
  #:mock-show-operation end

  include Trailblazer::Test::Assertion
  include Trailblazer::Test::Assertion::AssertExposes
  include Trailblazer::Test::Operation::Helper

  describe "#mock_step" do
    let(:default_params) { { seq: [] } }
    let(:expected_attrs) { {} }

    #:simple-mock-step
    it "mocks loading user" do
      mocked_show = mock_step(Show, path: [:load_user]) do |ctx|
        ctx[:user] = Struct.new(:name).new('Mocky')
      end

      assert_pass mocked_show, default_params, **{}  do |result|
        assert_equal result[:user].name, 'Mocky'

        #~method
        assert_equal result[:seq], [:some_complex_task, :make_call]
        #~method end
      end
    end
    #:simple-mock-step end

    it "mocks subprocess" do
      #:mock-subprocess
      new_activity = mock_step(Show, path: [Show::Complexity]) do
        true # no-op to avoid any Complexity
      end
      #:mock-subprocess end

      #~method
      assert_pass new_activity, default_params, **{} do |result|
        assert_equal result[:seq], [:load_user]
      end
      #~method end
    end

    it "mocks subprocess step" do
      #:mock-subprocess-step
      new_activity = mock_step(Show, path: [Show::Complexity, :some_complex_task]) do
        # Mock only single step from nested activity to do nothing
        true
      end
      #:mock-subprocess-step end

      #~method
      assert_pass new_activity, default_params, **{} do |result|
        assert_equal result[:seq], [:load_user, :make_call]
      end
      #~method end
    end

    it "mocks nested subprocess step" do
      #:mock-nested-subprocess-step
      new_activity = mock_step(Show, path: [Show::Complexity, Show::Complexity::ExternalApi, :make_call]) do
        # Some JSON response
        true
      end
      #:mock-nested-subprocess-step end

      #~method
      assert_pass new_activity, default_params, **{} do |result|
        assert_equal result[:seq], [:load_user, :some_complex_task]
      end
      #~method end
    end
  end
end
