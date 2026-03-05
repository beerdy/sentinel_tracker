require_relative "../../spec_helper"

RSpec.describe SentinelTracker::ClientDeviceEnrichmentRegistry do
  let(:configuration) { SentinelTracker::Configuration.new }

  it "строит user_agent_parser provider" do
    provider = described_class.build(configuration: configuration, provider_name: "user_agent_parser")

    expect(provider).to be_a(SentinelTracker::Providers::UserAgentParser::Provider)
  end

  it "строит client_payload provider" do
    provider = described_class.build(configuration: configuration, provider_name: "client_payload")

    expect(provider).to be_a(SentinelTracker::Providers::ClientPayload::Provider)
  end

  it "падает на неизвестном provider" do
    expect do
      described_class.build(configuration: configuration, provider_name: "ua_pro")
    end.to raise_error(ArgumentError, "Unknown client device enrichment provider: ua_pro")
  end

  it "падает на пустом provider name" do
    expect do
      described_class.build(configuration: configuration, provider_name: " ")
    end.to raise_error(ArgumentError, "Client device enrichment provider name is empty")
  end
end
