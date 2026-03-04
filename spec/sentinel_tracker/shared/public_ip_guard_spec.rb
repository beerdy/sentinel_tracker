require_relative "../../spec_helper"

RSpec.describe SentinelTracker::Shared::PublicIpGuard do
  it "возвращает true для публичного ip" do
    expect(described_class.public?(ip: "8.8.8.8")).to be(true)
  end

  it "возвращает false для private ip" do
    expect(described_class.public?(ip: "192.168.0.10")).to be(false)
  end

  it "возвращает false для невалидного ip" do
    expect(described_class.public?(ip: "not-an-ip")).to be(false)
  end
end
