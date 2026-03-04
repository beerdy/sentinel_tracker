require_relative "../../spec_helper"

RSpec.describe SentinelTracker::Resolvers::CurrentUserIdResolver do
  subject(:resolver) { described_class.new }

  it "достаёт user_id из session" do
    request = ActionDispatch::Request.new("rack.session" => { user_id: 17 })

    expect(resolver.call(request: request)).to eq(17)
  end

  it "достаёт user_id из devise session key" do
    request = ActionDispatch::Request.new(
      "rack.session" => { "warden.user.user.key" => [[42], "$2a$stub"] }
    )

    expect(resolver.call(request: request)).to eq(42)
  end
end
