require_relative "../spec_helper"

RSpec.describe SentinelTracker::Configuration do
  subject(:configuration) { described_class.new }

  it "по умолчанию выключен" do
    expect(configuration.enabled).to be(false)
  end

  it "нормализует target_login" do
    configuration.target_login = "  Admin@Example.COM "

    expect(configuration.normalized_target_login).to eq("admin@example.com")
  end

  it "имеет resolver для user_id" do
    request = ActionDispatch::Request.new("rack.session" => { user_id: 17 })

    expect(configuration.user_resolver.call(request: request)).to eq(17)
  end

  it "имеет generic настройки ip enrichment по умолчанию" do
    expect(configuration.security_event_enrichment_provider_name).to eq("ip_api")
    expect(configuration.security_event_enrichment_provider_options).to eq({})
  end

  it "имеет настройки network telemetry по умолчанию" do
    expect(configuration.network_telemetry_provider_names).to eq(["local_traceroute", "globalping"])
    expect(configuration.network_telemetry_provider_options).to eq({})
  end

  it "строит default network telemetry provider через factory" do
    providers = SentinelTracker::NetworkTelemetryRegistry.build_many(
      configuration: configuration,
      provider_names: configuration.network_telemetry_provider_names
    )

    expect(providers.map(&:class)).to eq(
      [
        SentinelTracker::Providers::LocalTraceroute::Provider,
        SentinelTracker::Providers::Globalping::Provider
      ]
    )
  end

  it "умеет переключаться на globalping provider" do
    configuration.network_telemetry_provider_names = ["globalping"]
    providers = SentinelTracker::NetworkTelemetryRegistry.build_many(
      configuration: configuration,
      provider_names: configuration.network_telemetry_provider_names
    )

    expect(providers.map(&:class)).to eq([SentinelTracker::Providers::Globalping::Provider])
  end

  it "умеет включать оба network telemetry provider" do
    configuration.network_telemetry_provider_names = ["local_traceroute", "globalping"]
    providers = SentinelTracker::NetworkTelemetryRegistry.build_many(
      configuration: configuration,
      provider_names: configuration.network_telemetry_provider_names
    )

    expect(providers.map(&:class)).to eq(
      [
        SentinelTracker::Providers::LocalTraceroute::Provider,
        SentinelTracker::Providers::Globalping::Provider
      ]
    )
  end

  it "позволяет прозрачно хранить provider options" do
    configuration.network_telemetry_provider_options = {
      "globalping" => { "api_url" => "https://api.globalping.io" }
    }

    expect(configuration.network_telemetry_provider_options["globalping"]["api_url"]).to eq("https://api.globalping.io")
  end
end
