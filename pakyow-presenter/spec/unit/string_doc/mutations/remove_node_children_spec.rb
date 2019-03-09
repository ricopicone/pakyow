require_relative "../shared_context"

RSpec.describe "StringDoc#remove_node_children" do
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

  context "node to remove exists" do
    it "removes the node's children" do
      doc.remove_node_children(node)
      expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"></article>")
    end

    it "returns self" do
      expect(doc.remove_node_children(doc.nodes[2])).to be(doc)
    end

    it "does not find children after removing" do
      doc.remove_node_children(node)
      expect(doc.find_significant_nodes_with_name(:binding, :title)).to be_empty
    end
  end

  context "node remove has deeply nested children" do
    let :html do
      <<~HTML
        <article binding="post">
          <h1 binding="title">title goes here</h1>
        </article>
      HTML
    end

    it "removes the deeply nested children" do
      doc.remove_node_children(node)
      expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"></article>")
    end
  end

  context "node to remove does not exist" do
    it "does not change the doc" do
      expect {
        doc.remove_node_children(StringDoc::Node.new)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.remove_node_children(StringDoc::Node.new)).to be(doc)
    end
  end

  context "the node to remove is not a node" do
    it "does not change the doc" do
      expect {
        doc.remove_node_children(StringDoc::Node.new)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.remove_node_children(:hi)).to be(doc)
    end
  end
end
