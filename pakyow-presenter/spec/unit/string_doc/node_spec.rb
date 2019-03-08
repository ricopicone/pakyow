RSpec.describe StringDoc::Node do
  let :html do
    "<div binding=\"post\"><h1 binding=\"title\">hello</h1></div>"
  end

  let :doc do
    StringDoc.new(html)
  end

  let :node do
    doc.find_significant_nodes_with_name(:binding, :post)[0]
  end

  describe "#attributes" do
    it "returns a StringDoc::Attributes instance" do
      expect(node.attributes).to be_instance_of(StringDoc::Attributes)
    end
  end

  describe "#tagname" do
    it "returns the tagname" do
      expect(node.tagname).to eq("div")
    end
  end

  describe "#label" do
    let :html do
      "<div binding=\"post\" version=\"foo\"><h1 binding=\"title\">hello</h1></div>"
    end

    context "label exists" do
      it "returns the value" do
        expect(node.label(:version)).to eq(:foo)
      end
    end

    context "label does not exist" do
      it "returns nil" do
        expect(node.label(:nonexistent)).to eq(nil)
      end
    end
  end

  describe "#labeled?" do
    let :html do
      "<div binding=\"post\" version=\"foo\"><h1 binding=\"title\">hello</h1></div>"
    end

    context "label exists" do
      it "returns true" do
        expect(node.labeled?(:version)).to eq(true)
      end
    end

    context "label does not exist" do
      it "returns false" do
        expect(node.labeled?(:nonexistent)).to eq(false)
      end
    end
  end

  describe "#inspect" do
    it "includes significance" do
      expect(node.inspect).to include("@significance=[:binding, :within_binding, :binding_within]")
    end

    it "includes labels" do
      expect(node.inspect).to include("@labels={:binding=>:post, :channel=>[], :combined_channel=>\"\"}")
    end

    it "includes attributes" do
      expect(node.inspect).to include("@attributes=#<StringDoc::Attributes")
    end
  end

  describe "#==" do
    it "returns true when the nodes are equal" do
      comparison = StringDoc.new(html).find_significant_nodes_with_name(:binding, :post)[0]
      expect(node == comparison).to be true
    end

    it "returns false when the nodes are not equal" do
      comparison = StringDoc.new("<article binding=\"post\"><h1 binding=\"title\">hello</h1></article>").nodes[0]
      expect(node == comparison).to be false
    end

    it "returns false when the comparison is not a StringDoc::Node" do
      expect(node == "").to be false
    end
  end
end
