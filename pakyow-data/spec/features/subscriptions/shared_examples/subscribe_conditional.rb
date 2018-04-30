RSpec.shared_examples :subscription_subscribe_conditional do
  describe "subscribing to a query with conditionals" do
    class TestHandler
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

    include_context "testable app"

    let :app_definition do
      Pakyow.config.data.default_adapter = :sql
      Pakyow.config.data.connections.sql[:default] = "sqlite::memory"
      Pakyow.config.data.subscriptions.adapter = data_subscription_adapter

      Proc.new do
        source :posts do
          primary_id

          attribute :title, :string
          attribute :body, :string

          subscribe :by_title, title: :__arg0__

          def by_title(title)
            where(title: title)
          end
        end

        resources :posts, "/posts" do
          skip_action :verify_same_origin
          skip_action :verify_authenticity_token

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

            data.posts.by_title(params[:id]).update(params[:post])
          end

          remove do
            data.posts.by_title(params[:id]).delete
          end

          collection do
            post "subscribe" do
              data.posts.by_title("foo").subscribe(:post_subscriber, handler: TestHandler)
            end

            post "unsubscribe" do
              data.subscribers.unsubscribe(:post_subscriber)
            end
          end
        end
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

    context "when an object covered by the query is created" do
      it "calls the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts", method: :post, params: { post: { title: "foo" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the query is updated" do
      it "calls the handler" do
        call("/posts", method: :post, params: { post: { title: "foo" } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts/foo", method: :patch, params: { post: { body: "bar" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the query is updated and now uncovered" do
      it "calls the handler" do
        call("/posts", method: :post, params: { post: { title: "foo" } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts/foo", method: :patch, params: { post: { title: "bar" } })
        expect(response[0]).to eq(200)
      end

      context "when that object is updated again" do
        it "does not call the handler" do
          call("/posts", method: :post, params: { post: { title: "foo" } })

          subscribe!
          call("/posts/foo", method: :patch, params: { post: { title: "bar" } })
          expect_any_instance_of(TestHandler).not_to receive(:call)
          response = call("/posts/bar", method: :patch, params: { post: { title: "baz" } })
          expect(response[0]).to eq(200)
        end
      end
    end

    context "when an object not previously covered by the query is updated and now covered" do
      it "calls the handler" do
        call("/posts", method: :post, params: { post: { title: "bar" } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts/foo", method: :patch, params: { post: { title: "foo" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the query is deleted" do
      it "calls the handler" do
        call("/posts", method: :post, params: { post: { title: "foo" } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts/foo", method: :delete)
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is created" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/posts", method: :post, params: { post: { title: "bar" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is updated and still not covered" do
      it "does not call the handler" do
        call("/posts", method: :post, params: { post: { title: "bar" } })

        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/posts/foo", method: :patch, params: { post: { title: "baz" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is deleted" do
      it "does not call the handler" do
        call("/posts", method: :post, params: { post: { title: "bar" } })

        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/posts/bar", method: :delete)
        expect(response[0]).to eq(200)
      end
    end
  end
end
