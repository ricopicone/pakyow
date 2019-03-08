require_relative "string_doc/shared_context"

RSpec.describe StringDoc do
  include_context :string_doc

  describe "#initialize" do
    it "initializes with an xml string" do
      expect(StringDoc.new("<div></div>")).to be_instance_of(StringDoc)
    end
  end
end
