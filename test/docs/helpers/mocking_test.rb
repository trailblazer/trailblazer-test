require "test_helper"

class DocsMockingTest < Minitest::Spec
  include Trailblazer::Test::Assertions
  include Trailblazer::Test::Operation::Assertions
  include Trailblazer::Test::Operation::Helper

  User = Struct.new(:name)

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

  describe "#mock_step" do
    let(:operation) { Show }
    let(:default_ctx) { { seq: [] } }
    let(:expected_attrs) { {} }

    #:simple-mock-step
    it "mocks loading user" do
      new_activity = mock_step(Show, id: :load_user) do |ctx|
        ctx[:user] = User.new('Mocky')
      end

      assert_pass({}, {}, operation: new_activity) do |ctx|
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
      assert_pass({}, {}, operation: new_activity) do |ctx|
        assert_equal ctx[:seq], [:load_user]
      end
      #~method end
    end

    it "mocks subprocess step" do
      #:mock-subprocess-step
      new_activity = mock_step(Show, id: :some_complex_task, subprocess_path: [Show::Complexity]) do
        # Mock only single step from nested activity to do nothing
        true
      end
      #:mock-subprocess-step end

      #~method
      assert_pass({}, {}, operation: new_activity) do |ctx|
        assert_equal ctx[:seq], [:load_user, :make_call]
      end
      #~method end
    end

    it "mocks nested subprocess step" do
      #:mock-nested-subprocess-step
      new_activity = mock_step(Show, id: :make_call, subprocess_path: [Show::Complexity, Show::Complexity::ExternalApi]) do
        # Some JSON response
        { name: 'Mocky' }
      end
      #:mock-nested-subprocess-step end

      #~method
      assert_pass({}, {}, operation: new_activity) do |ctx|
        assert_equal ctx[:seq], [:load_user, :some_complex_task]
      end
      #~method end
    end

    it "shows warning for deprecated `subprocess`" do
      #~method
      _, warning = capture_io do
        new_activity = mock_step(Show, id: :make_call, subprocess: Show::Complexity, subprocess_path: [Show::Complexity::ExternalApi]) do
          { name: 'Mocky' }
        end

        assert_pass({}, {}, operation: new_activity) do |ctx|
          assert_equal ctx[:seq], [:load_user, :some_complex_task]
        end
      end

      assert_match ":subprocess is deprecated and will be removed in 1.0.0. Pass `subprocess_path: #{[Show::Complexity, Show::Complexity::ExternalApi]}` instead.", warning
      #~method end
    end
  end
end
