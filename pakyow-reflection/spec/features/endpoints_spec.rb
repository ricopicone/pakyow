RSpec.describe "reflected endpoints" do
  let :app_definition do
    Proc.new do
      instance_exec(&$reflection_app_boilerplate)
    end
  end

  it "defines an endpoint at each view path the reflected type is used"

  # TODO: I think there are two aspects to this...
  #   1) don't want to override a controller
  #   2) don't want to override a route
  #
  # not entirely sure the best way to approach this actually
  it "does not overwrite existing endpoints"
end
