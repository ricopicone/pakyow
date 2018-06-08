RSpec.describe "presenting data in a channeled binding" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :published, data.posts.published
          expose :unpublished, data.posts.unpublished
          render "/channeled/posts"
        end

        create do
          verify do
            required :post do
              required :title
              required :published, :boolean
            end
          end

          data.posts.create(params[:post]); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
        attribute :published, :boolean

        def published
          where(published: true)
        end

        def unpublished
          where(published: false)
        end
      end

      presenter "/channeled/posts" do
        perform do
          find("post:published").present(published)
          find("post:unpublished").present(unpublished)
        end
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo", published: true } })
    call("/posts", method: :post, params: { post: { title: "bar", published: false } })

    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "baz", published: true } })
    end
  end
end

RSpec.describe "presenting data across channeled bindings" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/channeled/posts"
        end

        create do
          verify do
            required :post do
              required :title
              required :published, :boolean
            end
          end

          data.posts.create(params[:post]); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
        attribute :published, :boolean
      end

      presenter "/channeled/posts" do
        perform do
          find(:post).present(posts)
        end
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo", published: true } })
    call("/posts", method: :post, params: { post: { title: "bar", published: false } })

    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "baz", published: true } })
    end
  end
end
