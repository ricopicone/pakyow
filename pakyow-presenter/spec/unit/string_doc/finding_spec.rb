require_relative "shared_context"

RSpec.describe "StringDoc finding" do
  include_context :string_doc

  describe "#find_significant_nodes" do
    let :html do
      "<div binding=\"post\"><h1 binding=\"title\"></h1><p binding=\"body\"></p></div>"
    end

    context "nodes of the type are found" do
      it "returns the found nodes" do
        nodes = doc.find_significant_nodes(:binding)
        expect(nodes.count).to eq(3)
        expect(nodes.first).to be_instance_of(StringDoc::Node)
      end
    end

    context "no nodes of the type are found" do
      it "returns an empty array" do
        nodes = doc.find_significant_nodes(:body)
        expect(nodes).to eq([])
      end
    end

    context "doc contains significant children" do
      it "returns children" do
        nodes = doc.find_significant_nodes(:binding)
        expect(nodes.count).to eq(3)
      end
    end
  end

  describe "#find_significant_nodes_without_descending" do
    let :html do
      "<div binding=\"post\"><h1 binding=\"title\"></h1><p binding=\"body\"></p></div>"
    end

    context "nodes of the type are found" do
      it "returns the found nodes" do
        nodes = doc.find_significant_nodes_without_descending(:binding)
        expect(nodes.count).to eq(1)
        expect(nodes.first).to be_instance_of(StringDoc::Node)
      end
    end

    context "no nodes of the type are found" do
      it "returns an empty array" do
        nodes = doc.find_significant_nodes_without_descending(:body)
        expect(nodes).to eq([])
      end
    end

    context "doc contains significant children" do
      it "does not return children" do
        nodes = doc.find_significant_nodes_without_descending(:binding)
        expect(nodes.count).to eq(1)
      end
    end
  end

  describe "#find_significant_nodes_with_name" do
    let :html do
      "<div binding=\"post\"><h1 binding=\"title\"></h1><p binding=\"body\"></p></div>"
    end

    context "nodes of the type and name are found" do
      it "returns the found nodes" do
        nodes = doc.find_significant_nodes_with_name(:binding, :post)
        expect(nodes.count).to eq(1)
        expect(nodes.first).to be_instance_of(StringDoc::Node)
      end
    end

    context "no nodes of the type and name are found" do
      it "returns an empty array" do
        nodes = doc.find_significant_nodes_with_name(:binding, :foo)
        expect(nodes).to eq([])
      end
    end

    context "doc contains significant children" do
      it "returns children" do
        nodes = doc.find_significant_nodes_with_name(:binding, :title)
        expect(nodes.count).to eq(1)
      end
    end
  end

  describe "#find_significant_nodes_with_name_without_descending" do
    let :html do
      "<div binding=\"post\"><h1 binding=\"title\"></h1><p binding=\"body\"></p></div>"
    end

    context "nodes of the type and name are found" do
      it "returns the found nodes" do
        nodes = doc.find_significant_nodes_with_name_without_descending(:binding, :post)
        expect(nodes.count).to eq(1)
        expect(nodes.first).to be_instance_of(StringDoc::Node)
      end
    end

    context "no nodes of the type and name are found" do
      it "returns an empty array" do
        nodes = doc.find_significant_nodes_with_name_without_descending(:binding, :foo)
        expect(nodes).to eq([])
      end
    end

    context "doc contains significant children" do
      it "does not return children" do
        nodes = doc.find_significant_nodes_with_name_without_descending(:binding, :title)
        expect(nodes.count).to eq(0)
      end
    end
  end
end
