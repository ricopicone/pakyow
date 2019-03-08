require_relative "../shared_context"

RSpec.describe "StringDoc#append_to_node" do
  include_context :string_doc

  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  context "node to append after exists" do
    let :node do
      doc.find_significant_nodes_with_name(:binding, :post)[0]
    end

    context "appendable is a StringDoc" do
      let :appendable do
        StringDoc.new("<div>appendable</div>")
      end

      it "appends the node" do
        doc.append_to_node(node, appendable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1><div>appendable</div></article>")
      end

      it "returns self" do
        expect(doc.append_to_node(node, appendable)).to be(doc)
      end
    end

    context "appendable is a StringDoc::Node" do
      let :appendable do
        StringDoc.new("<div>appendable</div>").nodes[0]
      end

      it "appends the node" do
        doc.append_to_node(node, appendable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1><div>appendable</div></article>")
      end

      it "returns self" do
        expect(doc.append_to_node(node, appendable)).to be(doc)
      end
    end

    context "appendable is another object" do
      let :appendable do
        "<div>appendable</div>"
      end

      it "appends the node" do
        doc.append_to_node(node, appendable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1><div>appendable</div></article>")
      end

      it "returns self" do
        expect(doc.append_to_node(node, appendable)).to be(doc)
      end
    end

    context "node to append after is not a top level node" do
      let :node do
        doc.find_significant_nodes_with_name(:binding, :title)[0]
      end

      let :appendable do
        "<div>appendable</div>"
      end

      it "appends the node" do
        doc.append_to_node(node, appendable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here<div>appendable</div></h1></article>")
      end
    end

    context "appendable node has significant children" do
      let :appendable do
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

      it "appends with the children" do
        doc.append_to_node(node, *appendable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here<article data-b=\"comment\" data-c=\"article\"><p data-b=\"body\" data-c=\"article\">body goes here</p></article></h1></article>")
      end

      it "finds children after appendable" do
        doc.append_to_node(node, *appendable)
        expect(doc.find_significant_nodes_with_name(:binding, :title).count).to eq(1)
      end
    end

    context "appendable node has attached transformations" do
      let :appendable do
        doc = StringDoc.new("appendable")
        node = doc.nodes[0]
        doc.transform(node) do |node|
          "transformed"
        end

        [node, doc.children_for_node(node), doc.transformations_for_node(node)]
      end

      it "applies the transformations to the appendable" do
        doc.append_to_node(node, *appendable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1>transformed</article>")
      end
    end

    context "child of appendable node has attached transformations" do
      let :appendable do
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

      it "applies the transformations to the appendable" do
        doc.append_to_node(node, *appendable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1><article data-b=\"comment\" data-c=\"article\">transformed</article></article>")
      end
    end
  end

  context "the node does not exist" do
    let :appendable do
      StringDoc.new("<div>appendable</div>")
    end

    it "does not change the doc" do
      expect {
        doc.append_to_node(StringDoc::Node.new, appendable)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.append_to_node(StringDoc::Node.new, appendable)).to be(doc)
    end
  end

  context "the node to append after is not a node" do
    let :appendable do
      StringDoc.new("<div>appendable</div>")
    end

    it "does not change the doc" do
      expect {
        doc.append_to_node(StringDoc::Node.new, appendable)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.append_to_node(StringDoc::Node.new, appendable)).to be(doc)
    end
  end
end
