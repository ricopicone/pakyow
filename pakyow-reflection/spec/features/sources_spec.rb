RSpec.describe "reflected sources" do
  include_context "testable app"

  let :posts do
    Pakyow.apps.first.state_for(:source)[0]
  end

  let :comments do
    Pakyow.apps.first.state_for(:source)[1]
  end

  context "reflection is enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$reflection_app_boilerplate)

        configure :test do
          config.reflection.enabled = true
        end
      end
    end

    it "defines a source for each discovered type" do
      expect(posts.ancestors).to include(Pakyow::Data::Source)
      expect(comments.ancestors).to include(Pakyow::Data::Source)
    end

    describe "reflected source" do
      it "uses the sql adapter" do
        expect(
          posts.adapter
        ).to eq(:sql)
      end

      it "uses the configured connection" do
        expect(
          posts.connection
        ).to eq(Pakyow.apps.first.config.reflection.data.connection)
      end

      describe "reflected attributes" do
        it "has the correct number of attributes" do
          expect(posts.attributes.count).to eq(5)
          expect(comments.attributes.count).to eq(5)
        end

        it "defines an attribute for each discovered property" do
          expect(posts.attributes.keys).to include(:title)
          expect(posts.attributes[:title].primitive).to be(String)

          expect(posts.attributes.keys).to include(:body)
          expect(posts.attributes[:body].primitive).to be(String)

          expect(comments.attributes.keys).to include(:body)
          expect(comments.attributes[:body].primitive).to be(String)
        end

        it "defines a primary id by default" do
          expect(posts.attributes.keys).to include(:id)
          expect(posts.attributes[:id].primitive).to be(Integer)
          expect(posts.primary_key_field).to be(:id)

          expect(comments.attributes.keys).to include(:id)
          expect(comments.attributes[:id].primitive).to be(Integer)
          expect(comments.primary_key_field).to be(:id)
        end

        it "defines timestamps by default" do
          expect(posts.attributes.keys).to include(:created_at)
          expect(posts.attributes[:created_at].primitive).to be(DateTime)

          expect(posts.attributes.keys).to include(:updated_at)
          expect(posts.attributes[:updated_at].primitive).to be(DateTime)

          expect(comments.attributes.keys).to include(:created_at)
          expect(comments.attributes[:created_at].primitive).to be(DateTime)

          expect(comments.attributes.keys).to include(:updated_at)
          expect(comments.attributes[:updated_at].primitive).to be(DateTime)
        end
      end

      describe "reflected associations" do
        it "defines a has_many association for each nested type" do
          expect(posts.associations[:has_many].count).to be(1)
          expect(posts.associations[:has_many][0][:source_name]).to be(:comments)

          expect(comments.associations[:belongs_to].count).to be(1)
          expect(comments.associations[:belongs_to][0][:source_name]).to be(:posts)
        end
      end
    end

    context "source is already defined" do
      let :app_definition do
        Proc.new do
          instance_exec(&$reflection_app_boilerplate)

          source :posts do
            attribute :foo, :string
          end
        end
      end

      it "does not change the existing source" do
        expect(posts.attributes.count).to be(1)
      end
    end
  end

  context "reflection is disabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$reflection_app_boilerplate)

        configure :test do
          config.reflection.enabled = false
        end
      end
    end

    it "does not define a source for each discovered type" do
      expect(posts).to be(nil)
      expect(comments).to be(nil)
    end
  end
end
