require "test_helper"

# mock_step
class MockStepTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self)

  Memo = Module.new

  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :check_params
      step :verify_content

      include Testing.def_steps(:check_params, :verify_content)
    end

    class Create < Trailblazer::Operation
      step :model
      step Subprocess(Validate), id: :validate
      step :save

      include Testing.def_steps(:model, :save)
    end
  end

  it "allows mocking steps on first level" do
    create_operation = mock_step(Memo::Operation::Create, path: [:save]) do |ctx, **|
      # new logic for {save}.
      ctx[:saved] = true
    end

    result = create_operation.(seq: [])
    assert_equal result[:seq].inspect, %([:model, :check_params, :verify_content])
    assert_equal result[:saved], true

    result =
    assert_pass create_operation, {
      #~skip
      seq: []
      #~skip end
    }

    assert_equal result[:saved], true
  end

  it "allows mocking steps any level" do
    create_operation = mock_step(Memo::Operation::Create, path: [:validate, :verify_content]) do |ctx, **|
      # new logic for {Validate#verify_content}.
      ctx[:is_verified] = true
    end

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
