require_relative "../shared_context"

RSpec.describe "StringDoc#replace_node" do
  include_context :string_doc

  let :html do
    "<div>foo</div><div>bar</div><div>baz</div>"
  end

  context "node to replace exists" do
    context "replacement is a StringDoc" do
      let :replacement do
        StringDoc.new("<div>replacement</div>")
      end

      it "replaces the node" do
        doc.replace_node(doc.nodes[2], replacement)
        expect(doc.to_s).to eq("<div>foo</div><div>bar</div><div>replacement</div>")
      end

      it "returns self" do
        expect(doc.replace_node(doc.nodes[2], replacement)).to be(doc)
      end
    end

    context "replacement is a StringDoc::Node" do
      let :replacement do
        StringDoc.new("<div>replacement</div>").nodes[0]
      end

      it "replaces the node" do
        doc.replace_node(doc.nodes[2], replacement)
        expect(doc.to_s).to eq("<div>foo</div><div>bar</div><div>replacement</div>")
      end

      it "returns self" do
        expect(doc.replace_node(doc.nodes[2], replacement)).to be(doc)
      end
    end

    context "replacement is another object" do
      let :replacement do
        "<div>replacement</div>"
      end

      it "replaces the node" do
        doc.replace_node(doc.nodes[2], replacement)
        expect(doc.to_s).to eq("<div>foo</div><div>bar</div><div>replacement</div>")
      end

      it "returns self" do
        expect(doc.replace_node(doc.nodes[2], replacement)).to be(doc)
      end
    end

    context "node to replace is not a top level node" do
      let :html do
        "<div><div><div binding=\"foo\">foo</div></div></div>"
      end

      let :replacement do
        "bar"
      end

      it "replaces the node" do
        doc.replace_node(doc.find_significant_nodes_with_name(:binding, :foo)[0], replacement)
        expect(doc.to_s).to eq("<div><div>bar</div></div>")
      end
    end

    context "node to replace has significant children" do
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
        "replaced"
      end

      it "does not find children after replacement" do
        doc.replace_node(doc.find_significant_nodes_with_name(:binding, :author)[0], replacement)
        expect(doc.find_significant_nodes_with_name(:binding, :name)).to be_empty
      end
    end

    context "node to replace has attached transformations" do
      let :replacement do
        "replacement"
      end

      it "does not apply the transformations to the replacement" do
        node_to_replace = doc.nodes[0]
        doc.transform(node_to_replace) do |node|
          "transformed"
        end

        doc.replace_node(node_to_replace, replacement)
        expect(doc.to_s).to eq("replacement<div>bar</div><div>baz</div>")
      end
    end

    context "replacement node has significant children" do
      let :replacement do
        doc = StringDoc.new(
          <<~HTML
          <article binding="post">
            <h1 binding="title">title goes here</h1>
          </article>
          HTML
        )

        node = doc.nodes[0]
        [node, doc.children_for_node(node)]
      end

      it "replaces with the children" do
        doc.replace_node(doc.nodes[0], *replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article><div>bar</div><div>baz</div>")
      end

      it "finds children after replacement" do
        doc.replace_node(doc.nodes[0], *replacement)
        expect(doc.find_significant_nodes_with_name(:binding, :title).count).to eq(1)
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
        doc.replace_node(doc.nodes[0], *replacement)
        expect(doc.to_s).to eq("transformed<div>bar</div><div>baz</div>")
      end
    end

    context "child of replacement node has attached transformations" do
      let :replacement do
        doc = StringDoc.new(
          <<~HTML
            <article binding="post">
              <h1 binding="title">title goes here</h1>
            </article>
          HTML
        )

        node = doc.find_significant_nodes_with_name(:binding, :post)[0]

        doc.transform(doc.find_significant_nodes_with_name(:binding, :title)[0]) do |node|
          "transformed"
        end

        [node, doc.children_for_node(node), doc.transformations_for_node(node)]
      end

      it "applies the transformations to the replacement" do
        doc.replace_node(doc.nodes[0], *replacement)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\">transformed</article><div>bar</div><div>baz</div>")
      end
    end
  end

  context "the node does not exist" do
    let :replacement do
      StringDoc.new("<div>replacement</div>")
    end

    it "does not change the doc" do
      expect {
        doc.replace_node(StringDoc::Node.new, replacement)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.replace_node(StringDoc::Node.new, replacement)).to be(doc)
    end
  end

  context "the node to replace is not a node" do
    let :replacement do
      StringDoc.new("<div>replacement</div>")
    end

    it "does not change the doc" do
      expect {
        doc.replace_node(StringDoc::Node.new, replacement)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.replace_node(StringDoc::Node.new, replacement)).to be(doc)
    end
  end
end
