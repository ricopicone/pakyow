RSpec.shared_examples :subscription_subscribe_compound do
  describe "subscribing to a query with a compound value" do
    class TestHandler
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

    include_context "app"

    let :app_def do
      Pakyow.config.data.default_adapter = :sql
      Pakyow.config.data.subscriptions.adapter = data_subscription_adapter
      Pakyow.config.data.subscriptions.adapter_settings = data_subscription_adapter_settings

      Proc.new do
        Pakyow.after "configure" do
          config.data.connections.sql[:default] = "sqlite::memory"
        end
      end
    end

    let :app_init do
      Proc.new do
        source :posts do
          attribute :title, :string
          attribute :body, :string
        end

        resource :posts, "/posts" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          create do
            verify do
              required :post do
                required :title
                optional :body
              end
            end

            data.posts.create(params[:post])
          end

          update do
            verify do
              required :id

              required :post do
                optional :title
                optional :body
              end
            end

            data.posts.by_id(params[:id]).update(params[:post])
          end

          delete do
            data.posts.by_id(params[:id]).delete
          end

          collection do
            post "subscribe" do
              data.posts.by_id([1, 3]).subscribe(:post_subscriber, handler: TestHandler)
            end

            post "unsubscribe" do
              data.subscribers.unsubscribe(:post_subscriber)
            end
          end
        end
      end
    end

    before do
      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
        block.call
      end
    end

    after do
      unsubscribe!
    end

    def subscribe!
      response = call("/posts/subscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    def unsubscribe!
      response = call("/posts/unsubscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    before do
      data.posts.create(title: "foo title", body: "foo body")
      data.posts.create(title: "bar title", body: "bar body")
      data.posts.create(title: "baz title", body: "baz body")
    end

    context "when an object covered by the query is updated" do
      it "calls the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call).once
        response = call("/posts/1", method: :patch, params: { post: { title: "updated" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the query is deleted" do
      it "calls the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call).once
        response = call("/posts/3", method: :delete)
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is updated" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/posts/2", method: :patch, params: { post: { title: "updated" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is deleted" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/posts/2", method: :delete)
        expect(response[0]).to eq(200)
      end
    end
  end
end
