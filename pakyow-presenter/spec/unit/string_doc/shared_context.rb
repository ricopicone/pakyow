RSpec.shared_context :string_doc do
  using Pakyow::Support::DeepFreeze

  let :doc do
    StringDoc.new(html).deep_freeze.dup
  end
end
