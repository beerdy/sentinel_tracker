require_relative "../../spec_helper"

RSpec.describe SentinelTracker::RequestContextExtractor do
  subject(:extractor) { described_class.new }

  it "извлекает безопасный контекст запроса" do
    request = ActionDispatch::Request.new(
      "REQUEST_METHOD" => "POST",
      "PATH_INFO" => "/logins",
      "QUERY_STRING" => "page=1",
      "REMOTE_ADDR" => "127.0.0.1",
      "HTTP_X_FORWARDED_FOR" => "203.0.113.5",
      "HTTP_USER_AGENT" => "RSpec",
      "action_dispatch.request.request_parameters" => {
        "email" => "admin@example.com",
        "password" => "secret"
      },
      "action_dispatch.request_id" => "uuid-1"
    )

    payload = extractor.call(request: request)

    expect(payload[:request_method]).to eq("POST")
    expect(payload[:request_path]).to include("/logins")
    expect(payload[:ip]).to eq("203.0.113.5")
    expect(payload[:x_forwarded_for]).to eq("203.0.113.5")
    expect(payload[:params]["password"]).to eq("[FILTERED]")
  end
end
