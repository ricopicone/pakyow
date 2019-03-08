require_relative "../shared_context"

RSpec.describe "StringDoc#remove_node" do
  include_context :string_doc

  let :html do
    "<div>foo</div><div>bar</div><div>baz</div>"
  end

  context "node to remove exists" do
    it "deletes the node" do
      doc.remove_node(doc.nodes[2])
      expect(doc.to_s).to eq("<div>foo</div><div>bar</div>")
    end

    it "returns self" do
      expect(doc.remove_node(doc.nodes[2])).to be(doc)
    end

    context "node to remove has significant children" do
      let :html do
        <<~HTML
          <article binding="post">
            <h1 binding="title">title goes here</h1>
            <div binding="author">
              <span binding="name">name goes here</span>
            </div>
          </article>
        HTML
      end

      it "does not find children after removing" do
        doc.remove_node(doc.find_significant_nodes_with_name(:binding, :author)[0])
        expect(doc.find_significant_nodes_with_name(:binding, :name)).to be_empty
      end
    end
  end

  context "node to remove does not exist" do
    it "does not change the doc" do
      expect {
        doc.remove_node(StringDoc::Node.new)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.remove_node(StringDoc::Node.new)).to be(doc)
    end
  end

  context "the node to remove is not a node" do
    it "does not change the doc" do
      expect {
        doc.remove_node(StringDoc::Node.new)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.remove_node(:hi)).to be(doc)
    end
  end
end
