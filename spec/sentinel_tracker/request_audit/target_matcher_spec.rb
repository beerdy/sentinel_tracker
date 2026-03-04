require_relative "../../spec_helper"

RSpec.describe SentinelTracker::TargetMatcher do
  subject(:matcher) { described_class.new(configuration: configuration) }

  let(:configuration) { SentinelTracker::Configuration.new }

  before do
    configuration.enabled = true
  end

  it "матчит по target_user_id" do
    configuration.target_user_id = 42
    configuration.login_resolver = lambda do |_request|
      nil
    end
    request = ActionDispatch::Request.new("rack.session" => { user_id: 42 })

    expect(matcher.call(request: request)).to include(
      matched_by: "target_user_id",
      target_user_id: 42
    )
  end

  it "матчит по normalized login" do
    configuration.target_login = " Admin@Example.com "
    configuration.login_resolver = lambda do |_request|
      "admin@example.com"
    end

    request = ActionDispatch::Request.new({})

    expect(matcher.call(request: request)).to include(
      matched_by: "target_login",
      target_login: "admin@example.com"
    )
  end

  it "не матчит, если аудит выключен" do
    configuration.enabled = false
    configuration.target_user_id = 42
    request = ActionDispatch::Request.new("rack.session" => { user_id: 42 })

    expect(matcher.call(request: request)).to be_nil
  end
end
