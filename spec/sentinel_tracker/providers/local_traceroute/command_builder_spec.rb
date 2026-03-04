require_relative "../../../spec_helper"

RSpec.describe SentinelTracker::Providers::LocalTraceroute::CommandBuilder do
  subject(:builder) { described_class.new(traceroute_command_path: "/usr/sbin/traceroute") }

  it "собирает argv для публичного ip" do
    allow(File).to receive(:executable?).with("/usr/sbin/traceroute").and_return(true)

    expect(builder.call(ip: "8.8.8.8")).to eq(
      ["/usr/sbin/traceroute", "-q", "1", "-m", "8", "8.8.8.8"]
    )
  end

  it "возвращает nil для private ip" do
    allow(File).to receive(:executable?).with("/usr/sbin/traceroute").and_return(true)

    expect(builder.call(ip: "192.168.0.10")).to be_nil
  end

  it "возвращает nil для неисполняемой команды" do
    allow(File).to receive(:executable?).with("/usr/sbin/traceroute").and_return(false)

    expect(builder.call(ip: "8.8.8.8")).to be_nil
  end
end
