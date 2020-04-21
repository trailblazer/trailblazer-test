require "test_helper"

class DocsCallableTest < Minitest::Spec
  include Trailblazer::Test::Operation::Helper

  #:call
  it "calls the operation" do
    result = call Create, params: {title: "Shipwreck", band: "Rancid"}

    assert_equal true, result.success?
  end
  #:call end

  #:factory
  it "calls the operation and raises an error and prints trace when fails" do
    exp = assert_raises do
      factory Create, params: {title: "Shipwreck", band: "The Chats"}
    end

    exp.inspect.include? %(Operation trace)
    exp.inspect.include? "OperationFailedError: factory(Create) has failed due to validation "\
                         "errors: {:band=>['must be Rancid']}"
  end
  #:factory end
end
