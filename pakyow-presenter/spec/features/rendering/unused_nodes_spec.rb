RSpec.describe "unused nodes" do
  include_context "app"

  describe "unused bindings" do
    context "binding is not bound to" do
      it "removes the binding" do
        expect(call("/unused/bindings")[2].read).to include("<body><script")
      end
    end

    context "binding nil" do
      let :app_def do
        Proc.new do
          controller do
            get "/unused/bindings" do
              expose :post, nil
            end
          end
        end
      end

      it "removes the binding" do
        expect(call("/unused/bindings")[2].read).to include("<body><script")
      end
    end
  end

  describe "unused versions" do
    let :mode do
      # The best way to test this, since bindings won't be removed.
      #
      :prototype
    end

    context "when there are multiple views, one of them being versioned" do
      it "renders only the first one" do
        expect(call("/unused/versions/single")[2].read).to include("<body><div data-b=\"post\"><h1 data-b=\"title\">one</h1></div><style>")
      end
    end

    context "when there are multiple versions, including a default" do
      it "renders only the default" do
        expect(call("/unused/versions/multiple-with-default")[2].read).to include("<body><div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">default</h1></div><style>")
      end
    end

    context "when there are multiple versions, without a default" do
      it "renders neither" do
        expect(call("/unused/versions/multiple-sans-default")[2].read).to include("<body><style>")
      end
    end
  end
end
