require_relative "../shared_context"

RSpec.describe "StringDoc#delete_node_attribute" do
  include_context :string_doc

  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  before do
    doc.set_node_attribute(doc.find_significant_nodes_with_name(:binding, :post)[0], :class, "foo bar")
  end

  let :node do
    doc.find_significant_nodes_with_name(:binding, :post)[0]
  end

  it "deletes the attribute" do
    doc.delete_node_attribute(node, :class)
    expect(doc.find_significant_nodes_with_name(:binding, :post)[0].attributes[:class]).to be(nil)
  end

  it "reassigns children" do
    doc.delete_node_attribute(node, :class)
    expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>")
  end

  it "reassigns transformations" do
    doc.transform(node) do
      "transformed"
    end

    doc.delete_node_attribute(node, :foo)
    expect(doc.to_s).to eq("transformed")
  end
end
