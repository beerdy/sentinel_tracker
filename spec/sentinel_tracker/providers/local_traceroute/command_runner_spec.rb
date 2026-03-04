require_relative "../../../spec_helper"

RSpec.describe SentinelTracker::Providers::LocalTraceroute::CommandRunner do
  subject(:runner) { described_class.new(timeout_seconds: 2, max_output_length: 100) }

  it "возвращает completed для успешной команды" do
    process_status = instance_double(Process::Status, success?: true)
    allow(Open3).to receive(:capture3).and_return(["hop1\nhop2", "", process_status])

    expect(runner.call(command: ["/usr/sbin/traceroute", "8.8.8.8"])).to eq(
      network_telemetry_status: "completed",
      network_telemetry_output: "hop1\nhop2"
    )
  end

  it "возвращает failed для команды с ошибкой" do
    process_status = instance_double(Process::Status, success?: false)
    allow(Open3).to receive(:capture3).and_return(["", "permission denied", process_status])

    expect(runner.call(command: ["/usr/sbin/traceroute", "8.8.8.8"])).to eq(
      network_telemetry_status: "failed",
      network_telemetry_output: "permission denied"
    )
  end
end
