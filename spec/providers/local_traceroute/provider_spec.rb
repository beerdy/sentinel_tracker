require_relative "../../../spec_helper"

RSpec.describe SentinelTracker::Providers::LocalTraceroute::Provider do
  subject(:provider) do
    described_class.new(
      network_telemetry_command_builder: network_telemetry_command_builder,
      network_telemetry_command_runner: network_telemetry_command_runner
    )
  end

  let(:network_telemetry_command_builder) { instance_double(SentinelTracker::Providers::LocalTraceroute::CommandBuilder) }
  let(:network_telemetry_command_runner) { instance_double(SentinelTracker::Providers::LocalTraceroute::CommandRunner) }

  it "возвращает completed результат через traceroute provider" do
    allow(network_telemetry_command_builder).to receive(:call).with(ip: "8.8.8.8").and_return(["/usr/sbin/traceroute", "8.8.8.8"])
    allow(network_telemetry_command_runner).to receive(:call).with(command: ["/usr/sbin/traceroute", "8.8.8.8"]).and_return(
      network_telemetry_status: "completed",
      network_telemetry_output: "hop1\nhop2"
    )

    expect(provider.call(ip: "8.8.8.8")).to eq(
      network_telemetry_status: "completed",
      network_telemetry_output: "hop1\nhop2",
      provider_name: "local_traceroute",
      payload: { command: ["/usr/sbin/traceroute", "8.8.8.8"] }
    )
  end

  it "возвращает skipped если локальная команда недоступна" do
    allow(network_telemetry_command_builder).to receive(:call).with(ip: "8.8.8.8").and_return(nil)

    expect(provider.call(ip: "8.8.8.8")).to eq(
      network_telemetry_status: "skipped",
      network_telemetry_output: "network telemetry command unavailable for current environment",
      provider_name: "local_traceroute",
      payload: { reason: "command_unavailable" }
    )
  end
end
