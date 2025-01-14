RSpec.describe "securely redirecting requests" do
  include_context "app"

  let :app_def do
    Proc.new do
      after :load do
        @endpoints << Pakyow::Endpoint.new(
          name: :remote, method: :get, builder: -> (*) {
            "http://foo.com/destination"
          }
        )
      end

      controller :redirect do
        get "/redirect" do
          redirect "/destination"
        end

        get "/redirect/remote" do
          redirect "http://foo.com/destination"
        end

        get "/redirect/remote/trusted" do
          redirect "http://foo.com/destination", trusted: true
        end

        get "/redirect/remote/endpoint" do
          redirect :remote
        end

        get "/redirect/remote/endpoint/trusted" do
          redirect :remote, trusted: true
        end
      end
    end
  end

  describe "redirecting to a local path" do
    it "redirects" do
      expect(call("/redirect")[1]["location"]).to eq("/destination")
    end
  end

  describe "redirecting to a remote path" do
    let :allow_request_failures do
      true
    end

    it "does not redirect" do
      expect(call("/redirect/remote")[1]["location"]).to be(nil)
    end

    it "raises an error" do
      call("/redirect/remote")
      expect(connection.error).to be_instance_of(Pakyow::Security::InsecureRedirect)
      expect(connection.error.message).to eq("Cannot redirect to remote, untrusted location `http://foo.com/destination'")
    end

    context "redirect is trusted" do
      it "redirects" do
        expect(call("/redirect/remote/trusted")[1]["location"]).to eq("http://foo.com/destination")
      end
    end
  end

  describe "redirecting to a remote endpoint" do
    let :allow_request_failures do
      true
    end

    it "does not redirect" do
      expect(call("/redirect/remote/endpoint")[1]["location"]).to be(nil)
    end

    it "raises an error" do
      call("/redirect/remote/endpoint")
      expect(connection.error).to be_instance_of(Pakyow::Security::InsecureRedirect)
      expect(connection.error.message).to eq("Cannot redirect to remote, untrusted location `http://foo.com/destination'")
    end

    context "redirect is trusted" do
      it "redirects" do
        expect(call("/redirect/remote/endpoint/trusted")[1]["location"]).to eq("http://foo.com/destination")
      end
    end
  end
end
