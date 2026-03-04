require_relative "../../../spec_helper"

RSpec.describe SentinelTracker::Providers::Globalping::Provider do
  subject(:provider) do
    described_class.new(
      connection: connection,
      logger: logger,
      measurement_type: measurement_type,
      poll_interval_seconds: poll_interval_seconds,
      max_polls: max_polls
    )
  end

  let(:connection) { instance_double(Faraday::Connection) }
  let(:logger) { Logger.new(nil) }
  let(:measurement_type) { "traceroute" }
  let(:poll_interval_seconds) { 1 }
  let(:max_polls) { 3 }

  it "создаёт measurement и возвращает rawOutput после polling" do
    create_response = instance_double(Faraday::Response, body: { "id" => "measurement-1", "status" => "in-progress" })
    poll_response = instance_double(
      Faraday::Response,
      body: {
        "id" => "measurement-1",
        "status" => "finished",
        "results" => [
          {
            "result" => {
              "rawOutput" => "1 203.0.113.1\n2 8.8.8.8"
            }
          }
        ]
      }
    )

    allow(connection).to receive(:post).with(
      "v1/measurements",
      hash_including("target" => "8.8.8.8", "type" => "traceroute", "limit" => 1, "locations" => [])
    ).and_return(create_response)
    allow(connection).to receive(:get).with("v1/measurements/measurement-1").and_return(poll_response)

    expect(provider.call(ip: "8.8.8.8")).to eq(
      network_telemetry_status: "completed",
      network_telemetry_output: "1 203.0.113.1\n2 8.8.8.8",
      provider_name: "globalping"
    )
  end

  it "возвращает skipped для локального ip" do
    expect(provider.call(ip: "127.0.0.1")).to eq(
      network_telemetry_status: "skipped",
      network_telemetry_output: "globalping network telemetry skipped for non-public ip",
      provider_name: "globalping"
    )
  end

  it "возвращает failed если api отвечает error" do
    create_response = instance_double(Faraday::Response, body: { "error" => { "message" => "limit exceeded" } })
    allow(connection).to receive(:post).and_return(create_response)

    expect(provider.call(ip: "8.8.8.8")).to eq(
      network_telemetry_status: "failed",
      network_telemetry_output: "StandardError: globalping api error: limit exceeded",
      provider_name: "globalping"
    )
  end
end
