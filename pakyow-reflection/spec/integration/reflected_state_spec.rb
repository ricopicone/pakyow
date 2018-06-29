RSpec.describe "reflected state" do
  include_context "testable app"

  let :app_definition do
    local_template_store_path = template_store_path

    Proc.new do
      configure do
        config.presenter.path = File.join(
          File.expand_path("../", __FILE__),
          "support/views/#{local_template_store_path}")
      end
    end
  end

  let :reflection do
    Pakyow::Reflection::State.new(
      Pakyow.apps.first
    ).reflection
  end

  context "single scope" do
    let :template_store_path do
      "single"
    end

    it "reflects" do
      expect(reflection).to eq(
        post: {
          attributes: {
            title: {
              type: :string
            },

            body: {
              type: :string
            }
          },

          associations: []
        }
      )
    end
  end

  context "distributed scope" do
    let :template_store_path do
      "distributed"
    end

    it "reflects" do
      expect(reflection).to eq(
        post: {
          attributes: {
            title: {
              type: :string
            },

            body: {
              type: :string
            },

            published_at: {
              type: :datetime
            }
          },

          associations: []
        }
      )
    end
  end

  context "many scopes" do
    let :template_store_path do
      "many"
    end

    it "reflects" do
      expect(reflection).to eq(
        post: {
          attributes: {
            title: {
              type: :string
            },

            body: {
              type: :string
            }
          },

          associations: []
        },

        user: {
          attributes: {
            name: {
              type: :string
            }
          },

          associations: []
        }
      )
    end
  end

  context "scope nested within a single scope" do
    let :template_store_path do
      "nested"
    end

    it "reflects" do
      expect(reflection).to eq(
        post: {
          attributes: {
            title: {
              type: :string
            },

            body: {
              type: :string
            }
          },

          associations: [:comment]
        },

        comment: {
          attributes: {
            body: {
              type: :string
            }
          },

          associations: []
        }
      )
    end
  end

  context "scope nested within more than one scope" do
    let :template_store_path do
      "multi-nested"
    end

    it "reflects" do
      expect(reflection).to eq(
        post: {
          attributes: {
            title: {
              type: :string
            },

            body: {
              type: :string
            }
          },

          associations: [:comment]
        },

        message: {
          attributes: {
            title: {
              type: :string
            },

            body: {
              type: :string
            }
          },

          associations: [:comment]
        },

        comment: {
          attributes: {
            body: {
              type: :string
            }
          },

          associations: []
        }
      )
    end
  end
end
