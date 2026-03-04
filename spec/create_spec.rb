require_relative "../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::Create do
  subject(:use_case) do
    described_class.new(
      logger: logger,
      security_event_repository: security_event_repository,
      pipeline: pipeline
    )
  end

  let(:logger) { Logger.new(nil) }
  let(:security_event_repository) { instance_double(SentinelTracker::SecurityEventRepository) }
  let(:pipeline) { instance_double(SentinelTracker::SecurityEvents::Pipeline) }
  let(:payload) do
    {
      target_user_id: 42,
      target_login: "watch@example.com",
      request_uuid: "uuid-1",
      request_method: "POST",
      request_path: "/api/logins",
      ip: "8.8.8.8",
      x_forwarded_for: "203.0.113.1",
      user_agent: "RSpec",
      params: { "login" => { "user" => "watch@example.com" } }
    }
  end

  before do
    allow(SentinelTracker::SecurityEvent).to receive(:table_exists?).and_return(true)
  end

  it "сохраняет событие с enrichment полями из pipeline" do
    allow(pipeline).to receive(:call).with(payload: payload).and_return(
      asn: "AS15169 Google LLC",
      isp: "Google LLC",
      proxy: true,
      country: "United States",
      city: "Mountain View"
    )
    allow(security_event_repository).to receive(:create!).and_return(:created)

    use_case.call(payload: payload)

    expect(security_event_repository).to have_received(:create!).with(
      attributes: hash_including(
        target_user_id: 42,
        target_login: "watch@example.com",
        ip: "8.8.8.8",
        asn: "AS15169 Google LLC",
        isp: "Google LLC",
        proxy: true,
        country: "United States",
        city: "Mountain View",
        network_telemetry_status: "pending"
      )
    )
  end

  it "сохраняет событие без enrichment если pipeline вернул пустой hash" do
    allow(pipeline).to receive(:call).with(payload: payload).and_return({})
    allow(security_event_repository).to receive(:create!).and_return(:created)

    use_case.call(payload: payload)

    expect(security_event_repository).to have_received(:create!).with(
      attributes: hash_including(
        target_login: "watch@example.com",
        request_path: "/api/logins",
        network_telemetry_status: "pending"
      )
    )
  end
end
