require_relative "../shared_context"

RSpec.describe "StringDoc#replace_node_children" do
  include_context :string_doc

  # Must be significant in order to replace children.
  #
  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  context "node to replace children for exists" do
    let :node do
      doc.find_significant_nodes_with_name(:binding, :post)[0]
    end

    context "replacement is a StringDoc" do
      let :replacement do
        StringDoc.new("<div>replacement</div>")
      end

      it "replaces the node" do
        doc.replace_node_children(node, replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><div>replacement</div></article>")
      end

      it "returns self" do
        expect(doc.replace_node_children(node, replacement)).to be(doc)
      end
    end

    context "replacement is a StringDoc::Node" do
      let :replacement do
        StringDoc.new("<div>replacement</div>").nodes[0]
      end

      it "replaces the node" do
        doc.replace_node_children(node, replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><div>replacement</div></article>")
      end

      it "returns self" do
        expect(doc.replace_node_children(node, replacement)).to be(doc)
      end
    end

    context "replacement is another object" do
      let :replacement do
        "<div>replacement</div>"
      end

      it "replaces the node" do
        doc.replace_node_children(node, replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><div>replacement</div></article>")
      end

      it "returns self" do
        expect(doc.replace_node_children(node, replacement)).to be(doc)
      end
    end

    context "node to replace children for is not a top level node" do
      let :replacement do
        "<div>replacement</div>"
      end

      let :node do
        doc.find_significant_nodes_with_name(:binding, :title)[0]
      end

      it "replaces the node" do
        doc.replace_node_children(node, replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\"><div>replacement</div></h1></article>")
      end
    end

    context "node to replace children for has significant children" do
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

      let :replacement do
        "<div>replacement</div>"
      end

      let :node do
        doc.find_significant_nodes_with_name(:binding, :author)[0]
      end

      it "does not find children after replacement" do
        doc.replace_node_children(node, replacement)
        expect(doc.find_significant_nodes_with_name(:binding, :name)).to be_empty
      end
    end

    context "replaced child node has attached transformations" do
      let :replacement do
        "<div>replacement</div>"
      end

      it "does not apply the transformations to the replacement" do
        doc.transform(doc.find_significant_nodes_with_name(:binding, :title)[0]) do
          "transformed"
        end

        doc.replace_node_children(node, replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><div>replacement</div></article>")
      end
    end

    context "replacement node has significant children" do
      let :replacement do
        doc = StringDoc.new(
          <<~HTML
          <article binding="comment">
            <p binding="body">body goes here</p>
          </article>
          HTML
        )

        node = doc.nodes[0]
        [node, doc.children_for_node(node)]
      end

      it "replaces with the children" do
        doc.replace_node_children(node, *replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><article data-b=\"comment\" data-c=\"article\"><p data-b=\"body\" data-c=\"article\">body goes here</p></article></article>")
      end

      it "finds children after replacement" do
        doc.replace_node_children(doc.nodes[0], *replacement)
        expect(doc.find_significant_nodes_with_name(:binding, :body).count).to eq(1)
      end
    end

    context "replacement node has attached transformations" do
      let :replacement do
        doc = StringDoc.new("replacement")
        node = doc.nodes[0]
        doc.transform(node) do |node|
          "transformed"
        end

        [node, doc.children_for_node(node), doc.transformations_for_node(node)]
      end

      it "applies the transformations to the replacement" do
        doc.replace_node_children(node, *replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\">transformed</article>")
      end
    end

    context "child of replacement node has attached transformations" do
      let :replacement do
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

      it "applies the transformations to the replacement" do
        doc.replace_node_children(node, *replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><article data-b=\"comment\" data-c=\"article\">transformed</article></article>")
      end
    end
  end

  context "the node does not exist" do
    let :replacement do
      StringDoc.new("<div>replacement</div>")
    end

    it "does not change the doc" do
      expect {
        doc.replace_node_children(StringDoc::Node.new, replacement)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.replace_node_children(StringDoc::Node.new, replacement)).to be(doc)
    end
  end

  context "the node to replace children for is not a node" do
    let :replacement do
      StringDoc.new("<div>replacement</div>")
    end

    it "does not change the doc" do
      expect {
        doc.replace_node_children(StringDoc::Node.new, replacement)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.replace_node_children(StringDoc::Node.new, replacement)).to be(doc)
    end
  end
end
