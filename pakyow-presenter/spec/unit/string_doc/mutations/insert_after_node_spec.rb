require_relative "../shared_context"

RSpec.describe "StringDoc#insert_after_node" do
  include_context :string_doc

  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  context "node to insert after exists" do
    let :node do
      doc.find_significant_nodes_with_name(:binding, :post)[0]
    end

    context "insertable is a StringDoc" do
      let :insertable do
        StringDoc.new("<div>insertable</div>")
      end

      it "inserts the node" do
        doc.insert_after_node(node, insertable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article><div>insertable</div>")
      end

      it "returns self" do
        expect(doc.insert_after_node(node, insertable)).to be(doc)
      end
    end

    context "insertable is a StringDoc::Node" do
      let :insertable do
        StringDoc.new("<div>insertable</div>").nodes[0]
      end

      it "inserts the node" do
        doc.insert_after_node(node, insertable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article><div>insertable</div>")
      end

      it "returns self" do
        expect(doc.insert_after_node(node, insertable)).to be(doc)
      end
    end

    context "insertable is another object" do
      let :insertable do
        "<div>insertable</div>"
      end

      it "inserts the node" do
        doc.insert_after_node(node, insertable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article><div>insertable</div>")
      end

      it "returns self" do
        expect(doc.insert_after_node(node, insertable)).to be(doc)
      end
    end

    context "node to insert after is not a top level node" do
      let :node do
        doc.find_significant_nodes_with_name(:binding, :title)[0]
      end

      let :insertable do
        "<div>insertable</div>"
      end

      it "inserts the node" do
        doc.insert_after_node(node, insertable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1><div>insertable</div></article>")
      end
    end

    context "insertable node has significant children" do
      let :insertable do
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

      it "inserts with the children" do
        doc.insert_after_node(node, *insertable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1><article data-b=\"comment\" data-c=\"article\"><p data-b=\"body\" data-c=\"article\">body goes here</p></article></article>")
      end

      it "finds children after insertable" do
        doc.insert_after_node(node, *insertable)
        expect(doc.find_significant_nodes_with_name(:binding, :title).count).to eq(1)
      end
    end

    context "insertable node has attached transformations" do
      let :insertable do
        doc = StringDoc.new("insertable")
        node = doc.nodes[0]
        doc.transform(node) do |node|
          "transformed"
        end

        [node, doc.children_for_node(node), doc.transformations_for_node(node)]
      end

      it "applies the transformations to the insertable" do
        doc.insert_after_node(node, *insertable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article>transformed")
      end
    end

    context "child of insertable node has attached transformations" do
      let :insertable do
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

      it "applies the transformations to the insertable" do
        doc.insert_after_node(node, *insertable)
        expect(doc.to_s).to eq("<article data-b=\"post\" data-c=\"article\"><h1 data-b=\"title\" data-c=\"article\">title goes here</h1></article><article data-b=\"comment\" data-c=\"article\">transformed</article>")
      end
    end
  end

  context "the node does not exist" do
    let :insertable do
      StringDoc.new("<div>insertable</div>")
    end

    it "does not change the doc" do
      expect {
        doc.insert_after_node(StringDoc::Node.new, insertable)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.insert_after_node(StringDoc::Node.new, insertable)).to be(doc)
    end
  end

  context "the node to insert after is not a node" do
    let :insertable do
      StringDoc.new("<div>insertable</div>")
    end

    it "does not change the doc" do
      expect {
        doc.insert_after_node(StringDoc::Node.new, insertable)
      }.not_to change {
        doc.to_s
      }
    end

    it "returns self" do
      expect(doc.insert_after_node(StringDoc::Node.new, insertable)).to be(doc)
    end
  end
end
