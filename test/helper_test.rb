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
end
