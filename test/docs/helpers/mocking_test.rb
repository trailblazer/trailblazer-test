require "test_helper"

class DocsMockingTest < MiniTest::Spec
  #:mock-show-operation
  class Show < Trailblazer::Activity::FastTrack
    class Complexity < Trailblazer::Activity::FastTrack
      class ExternalApi < Trailblazer::Activity::FastTrack
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

  include Trailblazer::Test::Operation::Helper

  describe "#mock_step" do
    let(:default_params) { { seq: [] } }
    let(:expected_attrs) { {} }

    #:simple-mock-step
    it "mocks loading user" do
      new_activity = mock_step(Show, id: :load_user) do |ctx|
        ctx[:user] = Struct.new(:name).new('Mocky')
      end

      assert_pass new_activity, default_params, {} do |(signal, (ctx, flow_options))|
        assert_equal ctx[:user].name, 'Mocky'

        #~method
        assert_equal ctx[:seq], [:some_complex_task, :make_call]
        #~method end
      end
    end
    #:simple-mock-step end

    it "mocks subprocess" do
      #:mock-subprocess
      new_activity = mock_step(Show, id: Show::Complexity) do
        true # no-op to avoid any Complexity
      end
      #:mock-subprocess end

      #~method
      assert_pass new_activity, default_params, {} do |(signal, (ctx, flow_options))|
        assert_equal ctx[:seq], [:load_user]
      end
      #~method end
    end

    it "mocks subprocess step" do
      #:mock-subprocess-step
      new_activity = mock_step(Show, id: :some_complex_task, subprocess: Show::Complexity) do
        # Mock only single step from nested activity to do nothing
        true
      end
      #:mock-subprocess-step end

      #~method
      assert_pass new_activity, default_params, {} do |(signal, (ctx, flow_options))|
        assert_equal ctx[:seq], [:load_user, :make_call]
      end
      #~method end
    end

    it "mocks nested subprocess step" do
      #:mock-nested-subprocess-step
      new_activity = mock_step(Show, id: :make_call, subprocess: Show::Complexity, subprocess_path: [Show::Complexity::ExternalApi]) do
        # Some JSON response
      end
      #:mock-nested-subprocess-step end

      #~method
      assert_pass new_activity, default_params, {} do |(signal, (ctx, flow_options))|
        assert_equal ctx[:seq], [:load_user, :some_complex_task]
      end
      #~method end
    end
  end
end
