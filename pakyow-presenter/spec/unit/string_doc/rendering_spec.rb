require_relative "shared_context"

RSpec.describe "StringDoc rendering" do
  include_context :string_doc

  shared_examples :rendering do
    let :html do
      "<div>foo</div>"
    end

    it "converts the document to an xml string" do
      expect(doc.public_send(render_method)).to eq(html)
    end
  end

  describe "#render" do
    let :render_method do
      :render
    end

    include_examples :rendering
  end

  describe "#to_s" do
    let :render_method do
      :to_s
    end

    include_examples :rendering
  end

  describe "#to_xml" do
    let :render_method do
      :to_xml
    end

    include_examples :rendering
  end

  describe "#to_html" do
    let :render_method do
      :to_html
    end

    include_examples :rendering
  end
end
