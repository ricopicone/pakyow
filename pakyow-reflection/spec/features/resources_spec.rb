RSpec.describe "reflected resources" do
  include_context "testable app"

  let :posts do
    Pakyow.apps.first.state_for(:controller)[1]
  end

  let :comments do
    Pakyow.apps.first.state_for(:controller)[1].children[0]
  end

  # before do
  #   allow_any_instance_of(
  #     Pakyow::Security::CSRF::VerifySameOrigin
  #   ).to receive(:allowed?).and_return(true)
  # end

  context "reflection is enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$reflection_app_boilerplate)

        configure :test do
          config.reflection.enabled = true
        end

        controller :authenticity, "/authenticity" do
          default do
            send "#{authenticity_client_id}:#{authenticity_digest(authenticity_client_id)}"
          end
        end
      end
    end

    it "defines a controller for each top level discovered type" do
      expect(posts.ancestors).to include(Pakyow::Controller)
    end

    describe "nested resources" do
      it "defines a controller for each nested discovered type" do
        expect(comments.ancestors).to include(Pakyow::Controller)
      end

      it "nests the controller for the nested resource within its parent" do
        expect(comments.ancestors).to include(posts)
      end
    end

    describe "reflected resource" do
      describe "create endpoint" do
        let :params do
          {
            post: {
              title: "post one",
              body: "this is the first post"
            },

            authenticity_token: authenticity_token
          }
        end

        let :cookie do
          ""
        end

        let :response do
          call(
            "/posts",
            method: :post,
            params: params,
            "HTTP_COOKIE" => cookie,
            "HTTP_ORIGIN" => "http://example.org"
          )
        end

        context "without a valid authenticity token" do
          let :authenticity_token do
            "foo:bar"
          end

          it "fails to create an object for the passed values" do
            expect {
              expect(response[0]).to eq(403)
            }.not_to change {
              Pakyow.apps.first.data.posts.count
            }
          end
        end

        context "with a valid authenticity token" do
          let :authenticity_call do
            call("/authenticity")
          end

          let :authenticity_token do
            authenticity_call[2].body.read
          end

          let :cookie do
            authenticity_call[1]["Set-Cookie"]
          end

          it "creates an object for the passed values" do
            expect {
              expect(response[0]).to eq(200)
            }.to change {
              Pakyow.apps.first.data.posts.count
            }.from(0).to(1)
          end

          describe "validation" do
            it "fails when the type is not passed"
            it "succeeds when passed all attributes"
            it "succeeds when passed some attributes"
            it "succeeds when passed no attributes"
          end

          context "form origin is passed" do
            it "redirects back to the origin"
          end

          context "form origin is not passed" do
            it "responds 200, with an empty body"

            context "show endpoint is defined" do
              it "redirects to show"
            end

            context "list endpoint is defined" do
              it "redirects to the list"
            end
          end
        end
      end

      describe "update endpoint" do
        it "updates the object"

        describe "the lack of validation" do
          it "succeeds when passed all attributes"
          it "succeeds when passed some attributes"
          it "succeeds when passed no attributes"
        end

        context "form origin is passed" do
          it "redirects back to the origin"
        end

        context "form origin is not passed" do
          it "responds 200, with an empty body"

          context "show endpoint is defined" do
            it "redirects to show"
          end

          context "list endpoint is defined" do
            it "redirects to the list"
          end
        end

        context "object to update is not found" do
          it "returns 404"
        end
      end

      describe "delete endpoint" do
        it "deletes the object"

        context "form origin is passed" do
          it "redirects back to the origin"
        end

        context "form origin is not passed" do
          it "responds 200, with an empty body"

          context "list endpoint is defined" do
            it "redirects to the list"
          end
        end

        context "object to delete is not found" do
          it "returns 404"
        end
      end

      describe "list endpoint" do
        context "view path exists" do
          it "defines an html endpoint that exposes the objects"
        end

        context "view path does not exist" do
          it "does not define an html endpoint"
        end
      end

      describe "show endpoint" do
        context "view path exists" do
          it "defines an html endpoint that exposes the object"
        end

        context "view path does not exist" do
          it "does not define an html endpoint"
        end
      end

      describe "new endpoint" do
        context "view path exists" do
          it "defines an html endpoint"
        end

        context "view path does not exist" do
          it "does not define an html endpoint"
        end
      end

      describe "edit endpoint" do
        context "view path exists" do
          it "defines an html endpoint that exposes the object"
        end

        context "view path does not exist" do
          it "does not define an html endpoint"
        end
      end
    end

    context "source is defined explicitly rather than discovered" do
      it "creates a resource for the explicit source"
    end

    context "resource is already defined" do
      it "does not change the existing resource"
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

    it "does not defines a resource for each top level discovered type" do
      expect(posts).to be(nil)
    end
  end
end
