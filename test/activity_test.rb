require "test_helper"

# Test all assertions with a FastTrack class, not an Operation.
# TODO: This is currently not documented.
class AssertionActivityTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self, activity: true)
  Memo = Trailblazer::Test::Testing::Memo
  VALID_INPUT = Memo::VALID_INPUT # {params: {memo: {title: "TODO", content: "Stock up beer"}}}
  WTF_SUCCESS = %(AssertionActivityTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mcapture\e[0m
|-- model.build
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32m#<Trailblazer::Macro::Model::Find::NoArgument:XXX>\e[0m
|   `-- End.success
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[32mcontract.default.call\e[0m
|   `-- End.success
|-- \e[32mpersist.save\e[0m
`-- End.success
)
  WTF_FAILURE = %(AssertionActivityTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mcapture\e[0m
|-- model.build
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32m#<Trailblazer::Macro::Model::Find::NoArgument:XXX>\e[0m
|   `-- End.success
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[33mcontract.default.call\e[0m
|   `-- End.failure
`-- End.failure
)

  # DISCUSS: currently, we implicitly test that taskWrap is enabled
  #          when running the Create activity as Contract macros use tW.
  class Create < Trailblazer::Activity::FastTrack
    include Memo::Operation::Create::Capture
    step :capture
    step Model::Build(Memo, :new)
    step Contract::Build(constant: Memo::Operation::Create::Form)
    step Contract::Validate(key: :memo)
    step Contract::Persist()
  end

  # DISCUSS: we have to {ctx.dup} as we're not creating a real Context.

  it do
    assert_pass Create, VALID_INPUT.dup,
      title: "TODO"
  end

  it do
    assert_fail Create, {params: {memo: {}}}, [:title, :content]
  end

  it "allows tracing" do
    stdout, _ = capture_io do
      assert_pass?(Create, VALID_INPUT.dup, **{title: "TODO"})
    end

    stdout = stdout.sub(/0x\w+/, "XXX")

    assert_equal stdout, WTF_SUCCESS
  end
end

# Test with the Assertion::Suite "DSL" module.
class SuiteWithActivityTest < Minitest::Spec
  Trailblazer::Test::Assertion.module!(self, activity: true, suite: true)
  Create = AssertionActivityTest::Create

  let(:operation) { Create }
  let(:default_ctx) { {params: {memo: {content: "What about red wine?"}}} }
  let(:key_in_params) { :memo }

  it do
    stdout, _ = capture_io do
      assert_pass?({title: "Roxanne"}, {title: "Roxanne"})
    end

    stdout = stdout.sub(/0x\w+/, "XXX")

    assert_equal stdout, AssertionActivityTest::WTF_SUCCESS
  end

  it do
    stdout, _ = capture_io do
      assert_fail?({title: nil}, [:title])
    end

    stdout = stdout.sub(/0x\w+/, "XXX")

    assert_equal stdout, AssertionActivityTest::WTF_FAILURE
  end
end

require "trailblazer/endpoint"
require "trailblazer/test/endpoint"
class EndpointWithActivityTest < Minitest::Spec
  Create = AssertionActivityTest::Create
  Memo = Trailblazer::Test::Testing::Memo

  include Trailblazer::Test::Assertion
  include Trailblazer::Test::Assertion::Activity
  include Trailblazer::Test::Assertion::AssertExposes

  def self.__(activity, options, **kws, &block) # TODO: move this to endpoint.
    signal, (ctx, flow_options) = Trailblazer::Endpoint::Runtime.(
      activity, options,
      flow_options: _flow_options(),
      **kws,
      &block
    )

    return signal, ctx # DISCUSS: should we provide a Result object here?
  end

  def self.__?(*args, &block)
    __(*args, invoke_method: Trailblazer::Developer::Wtf.method(:invoke), &block)
  end
  include Trailblazer::Test::Endpoint.module(self, invoke_method: method(:__), invoke_method_wtf: method(:__?))


  def self._flow_options
    {
      context_options: {
        aliases: {"model": :object},
        container_class: Trailblazer::Context::Container::WithAliases,
      }
    }
  end


  it "{#assert_pass} {Activity} invoked via endpoint" do
    ctx = assert_pass Create, Memo::VALID_INPUT,
      title: "TODO"

    assert_equal ctx[:object].title, "TODO" # aliasing only works through endpoint.
  end

  it "{#assert_fail} with activity via endpoint" do
    ctx = assert_fail Create, {params: {memo: {}}}, [:title, :content]

    assert_equal ctx.class, Trailblazer::Context::Container::WithAliases
  end

  it "{#assert_pass?}" do
    stdout, _ = capture_io do
      ctx = assert_pass? Create, Memo::VALID_INPUT,
        title: "TODO"

      assert_equal ctx[:object].title, "TODO" # aliasing only works through endpoint.
    end

    stdout = stdout.sub(/0x\w+/, "XXX")

    assert_equal stdout, AssertionActivityTest::WTF_SUCCESS
  end

  it "{#assert_fail?}" do
    stdout, _ = capture_io do
      ctx = assert_fail? Create, {params: {memo: {}}}, [:title, :content]
    end

    stdout = stdout.sub(/0x\w+/, "XXX")

    assert_equal stdout, AssertionActivityTest::WTF_FAILURE
  end
end
