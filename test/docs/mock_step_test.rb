require "test_helper"

class MockStepTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self)

  Memo = Module.new

  #:validate
  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :check_params
      step :verify_content
      #~skip
      include Testing.def_steps(:check_params, :verify_content)
      #~skip end
    end
  end
  #:validate end

  #:create
  module Memo::Operation
    class Create < Trailblazer::Operation
      step :model
      step Subprocess(Validate), id: :validate
      step :save
      #~skip
      include Testing.def_steps(:model, :save)
      #~skip end
    end
  end
  #:create end

  it "allows mocking steps on first level" do
    #:create-mock
    create_operation = mock_step(Memo::Operation::Create, path: [:save]) do |ctx, **|
      # new logic for {save}.
      ctx[:saved] = true
    end
    #:create-mock end

    result =
    #:create-assert
    assert_pass create_operation, {
      #~skip
      seq: []
      #~skip end
    }
    #:create-assert end

    assert_equal result[:saved], true
    assert_equal result[:seq].inspect, %([:model, :check_params, :verify_content])

    result = create_operation.(seq: [])
    assert_equal result[:seq].inspect, %([:model, :check_params, :verify_content])
    assert_equal result[:saved], true
  end

  it "allows mocking steps any level" do
    #:mock-nested
    create_operation = mock_step(Memo::Operation::Create,
      path: [:validate, :verify_content]) do |ctx, **|
      # new logic for {Validate#verify_content}.
      ctx[:is_verified] = true
    end
    #:mock-nested end

    result = create_operation.(seq: [])
    assert_equal result[:seq].inspect, %([:model, :check_params, :save])
    assert_equal result[:is_verified], true

    result =
    assert_pass create_operation, {
      #~skip
      seq: []
      #~skip end
    }

    assert_equal result[:is_verified], true
  end
end
