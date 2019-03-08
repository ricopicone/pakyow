require_relative "../shared_context"

RSpec.describe "StringDoc#set_node_html" do
  include_context :string_doc

  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  it "replaces the node's children with the html" do
    node = doc.find_significant_nodes_with_name(:binding, :post)[0]
    doc.set_node_html(node, "foo")
    expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\">foo</article>")
  end

  it "returns the new node" do
    node = doc.find_significant_nodes_with_name(:binding, :post)[0]
    returned = doc.set_node_html(node, "foo")
    expect(returned).to be_instance_of(StringDoc::Node)
    expect(returned).to_not be(node)
  end
end
