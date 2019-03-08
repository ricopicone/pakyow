require_relative "../shared_context"

RSpec.describe "StringDoc#replace_node_attributes" do
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

  it "updates the attributes" do
    doc.replace_node_attributes(node, { class: "foo bar" })
    expect(doc.find_significant_nodes_with_name(:binding, :post)[0].attributes[:class]).to eq("foo bar")
  end

  it "reassigns children" do
    doc.replace_node_attributes(node, { class: "foo bar" })
    expect(doc.to_s).to eq("<article class=\"foo bar\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>")
  end

  it "reassigns transformations" do
    doc.transform(node) do
      "transformed"
    end

    doc.replace_node_attributes(node, { class: "foo bar" })
    expect(doc.to_s).to eq("transformed")
  end
end
