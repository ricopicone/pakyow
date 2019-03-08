require_relative "shared_context"

RSpec.describe "StringDoc#==" do
  include_context :string_doc

  let :html do
    "<div>foo</div>"
  end

  it "returns true when the documents are equal" do
    comparison = StringDoc.new(html)
    expect(doc == comparison).to be true
  end

  it "returns false when the documents are not equal" do
    comparison = StringDoc.new("<div>bar</div>")
    expect(doc == comparison).to be false
  end

  it "returns false when the comparison is not a StringDoc" do
    expect(doc == "").to be false
  end
end
