require_relative "../spec_helper"

RSpec.describe SentinelTracker::SecurityEventEnrichmentRegistry do
  let(:configuration) { SentinelTracker::Configuration.new }

  it "строит ip_api provider" do
    provider = described_class.build(configuration: configuration, provider_name: "ip_api")

    expect(provider).to be_a(SentinelTracker::Providers::IpApi::Provider)
  end

  it "падает на пустом provider name" do
    expect do
      described_class.build(configuration: configuration, provider_name: " ")
      end.to raise_error(ArgumentError, "Security event enrichment provider name is empty")
  end
end
