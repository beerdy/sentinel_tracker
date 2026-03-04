require_relative "../../spec_helper"

RSpec.describe SentinelTracker::NetworkTelemetryRegistry do
  let(:configuration) { SentinelTracker::Configuration.new }

  it "строит local_traceroute provider" do
    provider = described_class.build(configuration: configuration, provider_name: "local_traceroute")

    expect(provider).to be_a(SentinelTracker::Providers::LocalTraceroute::Provider)
  end

  it "строит globalping provider" do
    provider = described_class.build(configuration: configuration, provider_name: "globalping")

    expect(provider).to be_a(SentinelTracker::Providers::Globalping::Provider)
  end

  it "строит globalping provider только через provider options" do
    configuration.network_telemetry_provider_options = {
      "globalping" => {
        "api_url" => "https://api.globalping.io",
        "open_timeout" => 3,
        "read_timeout" => 4
      }
    }

    expect do
      described_class.build(configuration: configuration, provider_name: "globalping")
    end.not_to raise_error
  end

  it "строит оба provider одновременно" do
    providers = described_class.build_many(
      configuration: configuration,
      provider_names: ["local_traceroute", "globalping"]
    )

    expect(providers.map(&:class)).to eq(
      [
        SentinelTracker::Providers::LocalTraceroute::Provider,
        SentinelTracker::Providers::Globalping::Provider
      ]
    )
  end

  it "падает на неизвестном provider" do
    expect do
      described_class.build(configuration: configuration, provider_name: "custom_probe")
    end.to raise_error(ArgumentError, "Unknown network telemetry provider: custom_probe")
  end

  it "падает на пустом provider name" do
    expect do
      described_class.build(configuration: configuration, provider_name: " ")
    end.to raise_error(ArgumentError, "Network telemetry provider name is empty")
  end

  it "падает на пустом списке provider names" do
    expect do
      described_class.build_many(configuration: configuration, provider_names: [])
    end.to raise_error(ArgumentError, "Network telemetry providers list is empty")
  end
end
