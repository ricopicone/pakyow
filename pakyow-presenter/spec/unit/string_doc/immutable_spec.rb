require "string_doc/immutable"
require "pakyow/support/deep_freeze"

RSpec.describe StringDoc::Immutable do
  using Pakyow::Support::DeepFreeze

  describe "traversal" do
    it "returns a wrapped object"
  end

  describe "transformations" do
    let :html do
      <<~HTML
        <article binding="post">
          <h1 binding="title">title goes here</h1>
        </article>
      HTML
    end

    let :mutable do
      StringDoc.new(html)
    end

    let :immutable do
      StringDoc::Immutable.new(StringDoc.new(html).deep_freeze)
    end

    shared_examples :transformation do
      it "leads to the same result as mutable" do
        logic.call(mutable); logic.call(immutable)
        expect(immutable.render).to eq(mutable.render)
      end
    end

    describe "clear" do
      let :logic do
        Proc.new do |doc|
          doc.clear
        end
      end

      include_examples :transformation
    end

    describe "remove" do
      let :logic do
        Proc.new do |doc|
          doc.remove
        end
      end

      include_examples :transformation
    end

    describe "replace" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.replace("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.replace(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.replace(StringDoc.new("foo").nodes[0])
          end
        end

        include_examples :transformation
      end
    end

    describe "append" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.append("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.append(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.append(StringDoc.new("foo").nodes[0])
          end
        end

        include_examples :transformation
      end
    end

    describe "prepend" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.prepend("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.prepend(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.prepend(StringDoc.new("foo").nodes[0])
          end
        end

        include_examples :transformation
      end
    end

    describe "insert_after" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.insert_after("foo", doc.nodes[0])
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.insert_after(StringDoc.new("foo"), doc.nodes[0])
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.insert_after(StringDoc.new("foo").nodes[0], doc.nodes[0])
          end
        end

        include_examples :transformation
      end
    end

    describe "insert_before" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.insert_before("foo", doc.nodes[0])
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.insert_before(StringDoc.new("foo"), doc.nodes[0])
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.insert_before(StringDoc.new("foo").nodes[0], doc.nodes[0])
          end
        end

        include_examples :transformation
      end
    end

    describe "remove_node" do
      let :logic do
        Proc.new do |doc|
          doc.remove_node(doc.nodes[0])
        end
      end

      include_examples :transformation
    end

    describe "replace_node" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.replace_node(doc.nodes[0], "foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.replace_node(doc.nodes[0], StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.replace_node(doc.nodes[0], StringDoc.new("foo").nodes[0])
          end
        end

        include_examples :transformation
      end
    end
  end

  describe "node transformations" do
    let :html do
      <<~HTML
        <article binding="post">
          <h1 binding="title">title goes here</h1>
        </article>
      HTML
    end

    let :mutable do
      StringDoc.new(html)
    end

    let :immutable do
      StringDoc::Immutable.new(StringDoc.new(html).deep_freeze)
    end

    shared_examples :transformation do
      it "leads to the same result as mutable" do
        logic.call(mutable); logic.call(immutable)
        expect(immutable.render).to eq(mutable.render)
      end
    end

    describe "replace" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].replace("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].replace(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].replace(StringDoc::Node.new("foo"))
          end
        end

        include_examples :transformation
      end
    end

    describe "remove" do
      let :logic do
        Proc.new do |doc|
          doc.nodes[0].remove
        end
      end

      include_examples :transformation
    end

    describe "html=" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].html = "foo"
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].html = StringDoc.new("foo")
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].html = StringDoc::Node.new("foo")
          end
        end

        include_examples :transformation
      end
    end

    describe "replace_children" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].replace_children("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].replace_children(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].replace_children(StringDoc::Node.new("foo"))
          end
        end

        include_examples :transformation
      end
    end

    describe "clear" do
      let :logic do
        Proc.new do |doc|
          doc.nodes[0].clear
        end
      end

      include_examples :transformation
    end

    describe "after" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].after("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].after(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].after(StringDoc::Node.new("foo"))
          end
        end

        include_examples :transformation
      end
    end

    describe "before" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].before("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].before(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].before(StringDoc::Node.new("foo"))
          end
        end

        include_examples :transformation
      end
    end

    describe "append" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].append("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].append(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].append(StringDoc::Node.new("foo"))
          end
        end

        include_examples :transformation
      end
    end

    describe "prepend" do
      context "with a string" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].prepend("foo")
          end
        end

        include_examples :transformation
      end

      context "with a doc" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].prepend(StringDoc.new("foo"))
          end
        end

        include_examples :transformation
      end

      context "with a node" do
        let :logic do
          Proc.new do |doc|
            doc.nodes[0].prepend(StringDoc::Node.new("foo"))
          end
        end

        include_examples :transformation
      end
    end

    describe "set_label" do
      let :logic do
        Proc.new do |doc|
          doc.nodes[0].set_label(:foo, :bar)

          if doc.is_a?(StringDoc::Immutable)
            doc.transform(doc.nodes[0].object) do |node|
              StringDoc::Node::Immutable.set_html(node, node.label(:foo))
            end
          else
            doc.nodes[0].html = doc.nodes[0].label(:foo)
          end
        end
      end

      include_examples :transformation
    end

    describe "delete_label" do
      let :logic do
        Proc.new do |doc|
          doc.nodes[0].set_label(:foo, :bar)
          doc.nodes[0].delete_label(:foo)

          if doc.is_a?(StringDoc::Immutable)
            doc.transform(doc.nodes[0].object) do |node|
              StringDoc::Node::Immutable.set_html(node, node.label(:foo) || "missing")
            end
          else
            doc.nodes[0].html = doc.nodes[0].label(:foo) || "missing"
          end
        end
      end

      include_examples :transformation
    end
  end

  describe "attribute transformations" do
    let :html do
      <<~HTML
        <article binding="post">
          <h1 binding="title">title goes here</h1>
        </article>
      HTML
    end

    let :mutable do
      StringDoc.new(html)
    end

    let :immutable do
      StringDoc::Immutable.new(StringDoc.new(html).deep_freeze)
    end

    shared_examples :transformation do
      it "leads to the same result as mutable" do
        logic.call(mutable); logic.call(immutable)
        expect(immutable.render).to eq(mutable.render)
      end
    end

    describe "#[]=" do
      let :logic do
        Proc.new do |doc|
          doc.nodes[0].attributes[:class] = "foo bar"
        end
      end

      include_examples :transformation
    end

    describe "#delete" do
      let :logic do
        Proc.new do |doc|
          doc.nodes[0].attributes[:class] = "foo bar"
          doc.nodes[0].attributes.delete(:class)
        end
      end

      include_examples :transformation
    end
  end
end
