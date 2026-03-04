require_relative "../../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::TelemetryCollector do
  subject(:use_case) do
    described_class.new(
      logger: logger,
      security_event_repository: security_event_repository,
      security_event_network_telemetry_result_repository: security_event_network_telemetry_result_repository,
      network_telemetry_providers: network_telemetry_providers
    )
  end

  let(:logger) { Logger.new(nil) }
  let(:security_event_repository) { instance_double(SentinelTracker::SecurityEventRepository) }
  let(:security_event_network_telemetry_result_repository) { instance_double(SentinelTracker::SecurityEventNetworkTelemetryResultRepository) }
  let(:network_telemetry_provider) { instance_double(SentinelTracker::Providers::LocalTraceroute::Provider) }
  let(:globalping_provider) { instance_double(SentinelTracker::Providers::Globalping::Provider) }
  let(:network_telemetry_providers) { [network_telemetry_provider] }
  let(:security_event) { double("SecurityEvent", id: 11, ip: "8.8.8.8") }

  it "обновляет событие completed статусом" do
    allow(security_event_repository).to receive(:find).with(security_event_id: 11).and_return(security_event)
    allow(network_telemetry_provider).to receive(:call).with(ip: "8.8.8.8").and_return(
      network_telemetry_status: "completed",
      network_telemetry_output: "hop1\nhop2",
      provider_name: "local_traceroute"
    )
    allow(security_event_network_telemetry_result_repository).to receive(:save_result!)
    allow(security_event_repository).to receive(:update_network_telemetry_summary!)

    use_case.call(security_event_id: 11)

    expect(security_event_network_telemetry_result_repository).to have_received(:save_result!).with(
      security_event_id: 11,
      provider_name: "local_traceroute",
      status: "completed",
      output: "hop1\nhop2"
    )
    expect(security_event_repository).to have_received(:update_network_telemetry_summary!).with(
      security_event_id: 11,
      network_telemetry_status: "completed",
      network_telemetry_output: "local_traceroute: completed"
    )
  end

  it "ставит skipped если команда недоступна" do
    allow(security_event_repository).to receive(:find).with(security_event_id: 11).and_return(security_event)
    allow(network_telemetry_provider).to receive(:call).with(ip: "8.8.8.8").and_return(
      network_telemetry_status: "skipped",
      network_telemetry_output: "network telemetry command unavailable for current environment",
      provider_name: "local_traceroute"
    )
    allow(security_event_network_telemetry_result_repository).to receive(:save_result!)
    allow(security_event_repository).to receive(:update_network_telemetry_summary!)

    use_case.call(security_event_id: 11)

    expect(security_event_network_telemetry_result_repository).to have_received(:save_result!).with(
      security_event_id: 11,
      provider_name: "local_traceroute",
      status: "skipped",
      output: "network telemetry command unavailable for current environment"
    )
    expect(security_event_repository).to have_received(:update_network_telemetry_summary!).with(
      security_event_id: 11,
      network_telemetry_status: "skipped",
      network_telemetry_output: "local_traceroute: skipped"
    )
  end

  it "снимает метрики с обоих provider и агрегирует summary" do
    allow(security_event_repository).to receive(:find).with(security_event_id: 11).and_return(security_event)
    allow(network_telemetry_provider).to receive(:call).with(ip: "8.8.8.8").and_return(
      network_telemetry_status: "skipped",
      network_telemetry_output: "local unavailable",
      provider_name: "local_traceroute"
    )
    allow(globalping_provider).to receive(:call).with(ip: "8.8.8.8").and_return(
      network_telemetry_status: "completed",
      network_telemetry_output: "1 hop\n2 hop",
      provider_name: "globalping"
    )
    allow(security_event_network_telemetry_result_repository).to receive(:save_result!)
    allow(security_event_repository).to receive(:update_network_telemetry_summary!)

    described_class.new(
      logger: logger,
      security_event_repository: security_event_repository,
      security_event_network_telemetry_result_repository: security_event_network_telemetry_result_repository,
      network_telemetry_providers: [network_telemetry_provider, globalping_provider]
    ).call(security_event_id: 11)

    expect(security_event_network_telemetry_result_repository).to have_received(:save_result!).with(
      security_event_id: 11,
      provider_name: "local_traceroute",
      status: "skipped",
      output: "local unavailable"
    )
    expect(security_event_network_telemetry_result_repository).to have_received(:save_result!).with(
      security_event_id: 11,
      provider_name: "globalping",
      status: "completed",
      output: "1 hop\n2 hop"
    )
    expect(security_event_repository).to have_received(:update_network_telemetry_summary!).with(
      security_event_id: 11,
      network_telemetry_status: "completed",
      network_telemetry_output: "local_traceroute: skipped\nglobalping: completed"
    )
  end
end
