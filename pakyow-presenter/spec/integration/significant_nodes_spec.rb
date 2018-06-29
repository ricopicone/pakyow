RSpec.describe "significant nodes" do
  describe "containers" do
    it "needs specs"
  end

  describe "partials" do
    it "needs specs"
  end

  describe "scopes" do
    it "recognizes a binding that has an immediatly nested binding" do
      view = Pakyow::Presenter::View.new(
        <<~HTML
          <div binding="foo">
            <div binding="bar"></div>
          </div>
        HTML
      )

      expect(view.binding_scopes.count).to eq(1)
    end

    it "recognizes a binding that has a deeply nested binding" do
      view = Pakyow::Presenter::View.new(
        <<~HTML
          <div binding="foo">
            <div>
              <div binding="bar"></div>
            </div>
          </div>
        HTML
      )

      expect(view.binding_scopes.count).to eq(1)
    end
  end

  describe "props" do
    it "needs specs"
  end

  describe "components" do
    let :view do
      Pakyow::Presenter::View.new("<div ui=\"foo\"></div>")
    end

    it "sets data-ui" do
      expect(view.to_s).to eq("<div data-ui=\"foo\"></div>")
    end
  end

  describe "forms" do
    it "needs specs"
  end

  describe "options" do
    it "needs specs"
  end

  describe "optgroups" do
    it "needs specs"
  end

  describe "templates" do
    it "needs specs"
  end

  describe "title" do
    it "needs specs"
  end

  describe "body" do
    it "needs specs"
  end

  describe "head" do
    it "needs specs"
  end
end
