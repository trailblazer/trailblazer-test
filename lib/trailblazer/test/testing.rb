require "trailblazer/macro"
require "trailblazer/macro/contract"
# require "reform/form/active_model/validations" # FIXME: document!
require "dry-validation" #  FIXME: bug in reform-rails with Rails 6.1 errors object forces us to use dry-v until it's fixed.
require "trailblazer/operation"

module Trailblazer::Test
  # Test components we need in other gems, too.
  module Testing
    class Memo < Struct.new(:id, :title, :content, :tag_list, :persisted?, :errors, keyword_init: true)
      VALID_INPUT = {params: {memo: {title: "TODO", content: "Stock up beer"}}}.freeze

      def save
        self[:persisted?] = true
        self[:id] = 1
      end

      module Operation
        class Create < Trailblazer::Operation
          class Form < Reform::Form
            require "reform/form/dry"
            include Reform::Form::Dry

            property :title
            property :content
            property :tag_list

            validation do
              params do
                required(:title).filled
                required(:content).filled(min_size?: 8)
                optional(:tag_list).maybe(type?: String)
              end
            end
          end

          step :capture
          step Model::Build(Memo, :new)
          step Contract::Build(constant: Form)
          step Contract::Validate(key: :memo)
          step :parse_tag_list
          step Contract::Persist()

          module Capture
            def capture(ctx, **)
              ctx[:captured] = CU.inspect(ctx.to_h)
            end
          end
          include Capture

          def parse_tag_list(ctx, **)
            tag_list = ctx["contract.default"].tag_list or return true

            tags = tag_list.split(",")

            ctx["contract.default"].tag_list = tags
          end
        end # Create
      end
    end
  end
end
