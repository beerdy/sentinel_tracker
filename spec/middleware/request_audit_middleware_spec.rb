require_relative "../../spec_helper"

RSpec.describe SentinelTracker::RequestAuditMiddleware do
  let(:app) do
    lambda do |_env|
      [200, { "Content-Type" => "text/plain" }, ["ok"]]
    end
  end

  let(:request_context_extractor) { instance_double(SentinelTracker::RequestContextExtractor) }
  let(:target_matcher) { instance_double(SentinelTracker::TargetMatcher) }
  let(:logger) { Logger.new(nil) }
  let(:middleware) do
    described_class.new(
      app,
      request_context_extractor: request_context_extractor,
      target_matcher: target_matcher,
      logger: logger
    )
  end

  let(:env) do
    {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/profile",
      "REMOTE_ADDR" => "127.0.0.1",
      "rack.session" => {}
    }
  end

  it "не enqueue job для обычного запроса" do
    allow(request_context_extractor).to receive(:call).and_return(
      request_method: "GET",
      request_path: "/profile",
      ip: "127.0.0.1",
      x_forwarded_for: nil,
      user_agent: nil,
      request_uuid: nil,
      params: {}
    )
    allow(target_matcher).to receive(:call).and_return(nil)

    response = middleware.call(env)

    expect(response.first).to eq(200)
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to be_empty
  end

  it "enqueue job для target запроса" do
    allow(target_matcher).to receive(:call).and_return(
      matched_by: "target_user_id",
      target_user_id: 42,
      target_login: nil
    )
    allow(request_context_extractor).to receive(:call).and_return(
      request_method: "GET",
      request_path: "/profile",
      ip: "127.0.0.1",
      x_forwarded_for: nil,
      user_agent: nil,
      request_uuid: nil,
      params: {}
    )

    middleware.call(env)

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(1)
    payload = ActiveJob::Base.queue_adapter.enqueued_jobs.first[:args].first
    expect(payload["target_user_id"]).to eq(42)
    expect(payload["request_path"]).to eq("/profile")
  end

  it "не меняет ответ host-приложения при ошибке matcher" do
    allow(request_context_extractor).to receive(:call).and_return(
      request_method: "GET",
      request_path: "/profile",
      ip: "127.0.0.1",
      x_forwarded_for: nil,
      user_agent: nil,
      request_uuid: nil,
      params: {}
    )
    allow(target_matcher).to receive(:call).and_raise(StandardError, "matcher failed")

    response = middleware.call(env)

    expect(response.first).to eq(200)
  end

  it "не вызывает host-приложение повторно при ошибке matcher" do
    app_call_count = 0
    app_with_counter = lambda do |_env|
      app_call_count += 1
      [200, { "Content-Type" => "text/plain" }, ["ok"]]
    end
    middleware_with_counter = described_class.new(
      app_with_counter,
      request_context_extractor: request_context_extractor,
      target_matcher: target_matcher,
      logger: logger
    )
    allow(request_context_extractor).to receive(:call).and_return(
      request_method: "GET",
      request_path: "/profile",
      ip: "127.0.0.1",
      x_forwarded_for: nil,
      user_agent: nil,
      request_uuid: nil,
      params: {}
    )
    allow(target_matcher).to receive(:call).and_raise(StandardError, "matcher failed")

    middleware_with_counter.call(env)

    expect(app_call_count).to eq(1)
  end
end
