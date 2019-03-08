require_relative "shared_context"

RSpec.describe "StringDoc introspection" do
  include_context :string_doc

  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  let :node do
    doc.find_significant_nodes_with_name(:binding, :post)[0]
  end

  describe "#node_html" do
    it "returns the inner html of the node" do
      expect(doc.node_html(node)).to eq("<h1 data-b=\"title\" data-c=\"article\">title goes here</h1>")
    end
  end

  describe "#node_text" do
    it "returns the inner text of the node" do
      expect(doc.node_text(node)).to eq("title goes here")
    end
  end
end
