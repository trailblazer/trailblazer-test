require "test_helper"

class HelperTest < Minitest::Spec
  include Trailblazer::Test::Operation::Helper

  describe "#call" do
    #:call
    it "calls the operation" do
      result = call Create, params: {title: "Shipwreck", band: "Rancid"}

      assert_equal true, result.success?
    end
    #:call end

    it "calls the operation and does not raise an error when fails" do
      result = call Create, params: {title: "Shipwreck", band: "The Chats"}

      assert_equal true, result.failure?
    end

    describe "with a block" do
      it "calls the operation" do
        model = nil
        call Create, params: {title: "Shipwreck", band: "Rancid"} do |result|
          model = result[:model]
        end

        assert_equal model.title, "Shipwreck"
        assert_equal model.band, "Rancid"
      end

      it "calls the operation and does not raise an error when fails" do
        errors = nil
        call Create, params: {title: "Shipwreck", band: "The Chats"} do |result|
          errors = result["contract.default"].errors
        end

        assert_equal errors.messages, band: ["must be Rancid"]
      end
    end
  end

  describe "#factory" do
    it "calls the operation" do
      result = factory Create, params: {title: "Shipwreck", band: "Rancid"}

      assert_equal true, result.success?
    end

    it "calls the operation and raises an error and prints trace when fails" do
      exp = assert_raises do
        factory Create, params: {title: "Shipwreck", band: "The Chats"}
      end

      exp.inspect.include? %(Operation trace)
      exp.inspect.include? "OperationFailedError: factory(Create) has failed due to validation "\
                           "errors: {:band=>['must be Rancid']}"
    end

    describe "with a block" do
      it "calls the operation" do
        model = nil
        factory Create, params: {title: "Shipwreck", band: "Rancid"} do |result|
          model = result[:model]
        end

        assert_equal model.title, "Shipwreck"
        assert_equal model.band, "Rancid"
      end
    end
  end

  describe "#mock_step" do
    implementing = Testing.def_steps(:a, :b, :c, :d)

    deeply_nested = Class.new(Activity::Railway) do
      step implementing.method(:c), id: :c
    end

    nested = Class.new(Activity::Railway) do
      step implementing.method(:b), id: :b
      step Subprocess(deeply_nested)
    end

    activity = Class.new(Activity::Railway) do
      step implementing.method(:a), id: :a
      step Subprocess(nested)
      step implementing.method(:d), id: :d
    end

    it "allows to mock any step" do
      new_activity = mock_step(activity, id: :a) do |ctx|
        ctx[:seq] << :mocked_a
      end

      _, (ctx, _) = new_activity.(seq: [])
      assert_equal ctx[:seq], [:mocked_a, :b, :c, :d]
    end

    it "allows to mock any nested activity" do
      new_activity = mock_step(activity, id: nested) do |ctx|
        ctx[:seq] << :mocked_nested
      end

      _, (ctx, _) = new_activity.(seq: [])
      assert_equal ctx[:seq], [:a, :mocked_nested, :d]
    end

    it "allows to mock any step within nested activity" do
      new_activity = mock_step(activity, id: :b, subprocess: nested) do |ctx|
        ctx[:seq] << :mocked_b
      end

      _, (ctx, _) = new_activity.(seq: [])
      assert_equal ctx[:seq], [:a, :mocked_b, :c, :d]
    end

    it "allows to mock any deeply nested step within nested activity" do
      new_activity = mock_step(activity, id: :c, subprocess: nested, subprocess_path: [deeply_nested]) do |ctx|
        ctx[:seq] << :mocked_c
      end

      _, (ctx, _) = new_activity.(seq: [])
      assert_equal ctx[:seq], [:a, :b, :mocked_c, :d]
    end

    it "raises an exception if step's block is not given" do
      exception = assert_raises ArgumentError do
        mock_step(activity, id: :a)
      end

      assert_equal exception.message, "Missing block: `mock_step` requires a block."
    end
  end
end
