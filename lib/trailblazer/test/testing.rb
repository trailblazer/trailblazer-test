require "trailblazer/macro"
require "trailblazer/macro/contract"
# require "reform/form/active_model/validations" # FIXME: document!
require "dry-validation" #  FIXME: bug in reform-rails with Rails 6.1 errors object forces us to use dry-v until it's fixed.
require "trailblazer/operation"

module Trailblazer::Test
  # Test components we need in other gems, too.
  module Testing
    class Memo < Struct.new(:id, :title, :content, :persisted?, :errors)
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

            validation do
             params do
                required(:title).filled
                required(:content).filled(min_size?: 8)
              end
            end
          end

          step Model::Build(Memo, :new)
          step Contract::Build(constant: Form)
          step Contract::Validate(key: :memo)
          step Contract::Persist()
        end
      end
    end

    Song = Struct.new(:band, :title, :duration) do
      def save()
        @save = true
      end

      def persisted?
        !! @save
      end
    end

    module Song::Contract
      class Create < Reform::Form
        property :band
        property :title
        property :duration

        require "reform/form/dry"
        include Reform::Form::Dry
        validation do
          params do
            required(:title).filled
            optional(:duration).maybe(type?: String)
            required(:band).filled
          end
        end
        # validates :band, presence: true
      end
    end

    module Song::Operation
      class Create < Trailblazer::Operation
        step Model(Song, :new)
        step Contract::Build(constant: Song::Contract::Create)
        step Contract::Validate(key: :song)
        step :parse_duration
        step Contract::Persist()

        def parse_duration(ctx, **)
          duration = ctx["contract.default"].duration or return true

          m = duration.match(/(\d)\.(\d\d)$/)
          duration_seconds = m[1].to_i*60 + m[2].to_i

          ctx["contract.default"].duration = duration_seconds
        end
      end
    end
  end
end
