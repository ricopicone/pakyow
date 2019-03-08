require_relative "../shared_context"

RSpec.describe "StringDoc#prepend_to_node" do
  include_context :string_doc

  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  context "node to prepend after exists" do
    let :node do
      doc.find_significant_nodes_with_name(:binding, :post)[0]
    end

    context "prependable is a StringDoc" do
      let :prependable do
        StringDoc.new("<div>prependable</div>")
      end

      it "prepends the node" do
        doc.prepend_to_node(node, prependable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><div>prependable</div><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>")
      end

      it "returns self" do
        expect(doc.prepend_to_node(node, prependable)).to be(doc)
      end
    end

    context "prependable is a StringDoc::Node" do
      let :prependable do
        StringDoc.new("<div>prependable</div>").nodes[0]
      end

      it "prepends the node" do
        doc.prepend_to_node(node, prependable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><div>prependable</div><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>")
      end

      it "returns self" do
        expect(doc.prepend_to_node(node, prependable)).to be(doc)
      end
    end

    context "prependable is another object" do
      let :prependable do
        "<div>prependable</div>"
      end

      it "prepends the node" do
        doc.prepend_to_node(node, prependable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><div>prependable</div><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>")
      end

      it "returns self" do
        expect(doc.prepend_to_node(node, prependable)).to be(doc)
      end
    end

    context "node to prepend after is not a top level node" do
      let :node do
        doc.find_significant_nodes_with_name(:binding, :title)[0]
      end

      let :prependable do
        "<div>prependable</div>"
      end

      it "prepends the node" do
        doc.prepend_to_node(node, prependable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\"><div>prependable</div>title goes here</h1></article>")
      end
    end

    context "prependable node has significant children" do
      let :prependable do
        doc = StringDoc.new(
          <<~HTML
          <article binding="comment">
            <p binding="body">body goes here</p>
          </article>
          HTML
        )

        node = doc.find_significant_nodes_with_name(:binding, :comment)[0]
        [node, doc.children_for_node(node)]
      end

      let :node do
        doc.find_significant_nodes_with_name(:binding, :title)[0]
      end

      it "prepends with the children" do
        doc.prepend_to_node(node, *prependable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\"><article data-b=\"comment\" data-c=\"article\"><p data-b=\"body\" data-c=\"article\">body goes here</p></article>title goes here</h1></article>")
      end

      it "finds children after prependable" do
        doc.prepend_to_node(node, *prependable)
        expect(doc.find_significant_nodes_with_name(:binding, :title).count).to eq(1)
      end
    end

    context "prependable node has attached transformations" do
      let :prependable do
        doc = StringDoc.new("prependable")
        node = doc.nodes[0]
        doc.transform(node) do |node|
          "transformed"
        end

        [node, doc.children_for_node(node), doc.transformations_for_node(node)]
      end

      it "applies the transformations to the prependable" do
        doc.prepend_to_node(node, *prependable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\">transformed<h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>")
      end
    end

    context "child of prependable node has attached transformations" do
      let :prependable do
        doc = StringDoc.new(
          <<~HTML
            <article binding="comment">
              <p binding="body">body goes here</p>
            </article>
          HTML
        )

        node = doc.find_significant_nodes_with_name(:binding, :comment)[0]

        doc.transform(doc.find_significant_nodes_with_name(:binding, :body)[0]) do
          "transformed"
        end

        [node, doc.children_for_node(node), doc.transformations_for_node(node)]
      end

      it "applies the transformations to the prependable" do
        doc.prepend_to_node(node, *prependable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><article data-b=\"comment\" data-c=\"article\">transformed</article><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>")
      end
    end
  end

  context "the node does not exist" do
    let :prependable do
      StringDoc.new("<div>prependable</div>")
    end

    it "does not change the doc" do
      expect {
        doc.prepend_to_node(StringDoc::Node.new, prependable)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.prepend_to_node(StringDoc::Node.new, prependable)).to be(doc)
    end
  end

  context "the node to prepend after is not a node" do
    let :prependable do
      StringDoc.new("<div>prependable</div>")
    end

    it "does not change the doc" do
      expect {
        doc.prepend_to_node(StringDoc::Node.new, prependable)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.prepend_to_node(StringDoc::Node.new, prependable)).to be(doc)
    end
  end
end
