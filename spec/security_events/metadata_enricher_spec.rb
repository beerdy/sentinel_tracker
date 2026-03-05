require_relative "../../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::MetadataEnricher do
  subject(:enricher) { described_class.new(provider: provider) }

  let(:provider) { instance_double(SentinelTracker::Providers::IpApi::Provider) }
  let(:payload) { { ip: "8.8.8.8" } }

  it "маппит provider-ответ в атрибуты security event" do
    allow(provider).to receive(:provider_name).and_return("ip_api")
    allow(provider).to receive(:call).with(ip: "8.8.8.8").and_return(
      asn: "AS15169 Google LLC",
      isp: "Google LLC",
      proxy: true,
      country: "United States",
      city: "Mountain View",
      payload: { provider_name: "ip_api", response_status: "success" }
    )

    expect(enricher.call(payload: payload)).to eq(
      asn: "AS15169 Google LLC",
      isp: "Google LLC",
      proxy: true,
      country: "United States",
      city: "Mountain View",
      params_json_patch: {
        "security_event_enrichment" => {
          "provider_name" => "ip_api",
          "payload" => {
            "provider_name" => "ip_api",
            "response_status" => "success"
          }
        }
      }
    )
  end

  it "возвращает shape с nil значениями, если provider не дал enrichment" do
    allow(provider).to receive(:call).with(ip: "8.8.8.8").and_return({})

    expect(enricher.call(payload: payload)).to eq(
      asn: nil,
      isp: nil,
      proxy: nil,
      country: nil,
      city: nil
    )
  end
end
