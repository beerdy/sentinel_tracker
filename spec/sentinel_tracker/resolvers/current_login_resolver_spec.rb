require_relative "../../spec_helper"

RSpec.describe SentinelTracker::Resolvers::CurrentLoginResolver do
  subject(:resolver) { described_class.new }

  it "достаёт login из authorization token" do
    request = ActionDispatch::Request.new("HTTP_AUTHORIZATION" => "plainlogin_abcdef")

    expect(resolver.call(request: request)).to eq("plainlogin")
  end

  it "достаёт login из cookie token" do
    request = ActionDispatch::Request.new(
      "HTTP_COOKIE" => "token=cookielogin_abcdef"
    )

    expect(resolver.call(request: request)).to eq("cookielogin")
  end

  it "достаёт login из params" do
    request = ActionDispatch::Request.new(
      "action_dispatch.request.request_parameters" => {
        "login" => { "user" => "paramlogin" }
      }
    )

    expect(resolver.call(request: request)).to eq("paramlogin")
  end
end
