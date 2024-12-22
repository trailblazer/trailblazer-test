module Trailblazer::Test::Operation
  module Helper
    def mock_step(activity, path:, &block)
      raise ArgumentError, "Missing block: `#mock_step` requires a block." unless block_given?

      mocked_step_id, path = path.last, path[0..-2]

      mock_step = ->(ctx, **) { yield(ctx) }
      mock_instruction = -> { step mock_step, replace: mocked_step_id }


      Trailblazer::Activity::DSL::Linear::Patch.(activity, path, mock_instruction)
    end
  end
end

# [:delete_assets] => -> { step Destroy.method(:tidy_storage), before: :rm_uploads }
