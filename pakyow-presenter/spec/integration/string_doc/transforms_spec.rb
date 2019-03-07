RSpec.describe "transforming at render time" do
  let :html do
    <<~HTML
      <article binding="post">
        <h1 binding="title">title goes here</h1>
      </article>
    HTML
  end

  let :doc do
    StringDoc.new(html)
  end

  describe "attaching transformations to a doc" do
    it "transforms" do
      doc.transform do |doc|
        doc.clear
      end

      expect(doc.to_html).to eq_sans_whitespace("")
    end

    describe "priority" do
      it "transforms in order" do
        doc.transform priority: :default do |doc|
          doc.clear
        end

        doc.transform priority: :low do |doc|
          doc.append("bar")
        end

        doc.transform priority: :high do |doc|
          doc.append("foo")
        end

        expect(doc.to_html).to eq_sans_whitespace("bar")
      end
    end

    describe "evaluation context" do
      before do
        stub_const "Context", Class.new
        doc.transform do |doc|
          doc.replace(self.class.name)
        end
      end

      it "defaults to the stringdoc" do
        expect(doc.to_html).to eq_sans_whitespace(
          <<~HTML
            StringDoc
          HTML
        )
      end

      context "evaluation context is passed" do
        it "is the passed context" do
          expect(doc.to_html(context: Context.new)).to eq_sans_whitespace(
            <<~HTML
              Context
            HTML
          )
        end
      end
    end
  end

  describe "attaching transformations to a node" do
    it "transforms" do
      doc.find_significant_nodes_with_name(:binding, :title)[0].transform do |node|
        nil
      end

      expect(doc.to_html).to eq_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article"></article>
        HTML
      )
    end
  end

  describe "attaching transformations to a node's attributes" do
    it "transforms" do
      doc.find_significant_nodes_with_name(:binding, :title)[0].attributes.transform do |attributes|
        attributes[:class] = "foo bar"; attributes
      end

      expect(doc.to_html).to eq_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article">
            <h1 data-b="title" data-c="article" class="foo bar">title goes here</h1>
          </article>
        HTML
      )
    end
  end
end
