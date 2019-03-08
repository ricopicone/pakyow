RSpec.describe "StringDoc transformation" do
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

  context "transformation returns nil" do
    it "transforms" do
      doc.transform(doc.find_significant_nodes_with_name(:binding, :title)[0]) do |node|
        nil
      end

      expect(doc.to_html).to eq_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article"></article>
        HTML
      )
    end
  end

  context "transformation returns a string" do
    it "transforms" do
      doc.transform(doc.find_significant_nodes_with_name(:binding, :title)[0]) do |node|
        "foo"
      end

      expect(doc.to_html).to eq_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article">foo</article>
        HTML
      )
    end
  end

  context "transformation returns the node" do
    it "transforms" do
      doc.transform(doc.find_significant_nodes_with_name(:binding, :title)[0]) do |node|
        node
      end

      expect(doc.to_html).to eq_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article"><h1 data-b="title" data-c="article">title goes here</h1></article>
        HTML
      )
    end
  end

  context "transformation fails" do
    it "uses the content returned from the error handler" do
      error_handler = Proc.new { |error, node|
        "#{node}: #{error.message}"
      }

      transformed_node = doc.find_significant_nodes_with_name(:binding, :title)[0]
      doc.transform(transformed_node) do |node|
        fail "failed"
      end

      expect(doc.to_html(on_error: error_handler)).to eq_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article">#{transformed_node}: failed</article>
        HTML
      )
    end

    context "no error handler is defined" do
      it "removes the node that failed to render" do
        doc.transform(doc.find_significant_nodes_with_name(:binding, :title)[0]) do |node|
          fail "failed"
        end

        expect(doc.to_html).to eq_sans_whitespace(
          <<~HTML
            <article data-b="post" data-c="article"></article>
          HTML
        )
      end
    end
  end
end
