require_relative "../../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::MetadataEnricher do
  subject(:enricher) { described_class.new(provider: provider) }

  let(:provider) { instance_double(SentinelTracker::Providers::IpApi::Provider) }
  let(:payload) { { ip: "8.8.8.8" } }

  it "маппит provider-ответ в атрибуты security event" do
    allow(provider).to receive(:call).with(ip: "8.8.8.8").and_return(
      asn: "AS15169 Google LLC",
      isp: "Google LLC",
      proxy: true,
      country: "United States",
      city: "Mountain View"
    )

    expect(enricher.call(payload: payload)).to eq(
      asn: "AS15169 Google LLC",
      isp: "Google LLC",
      proxy: true,
      country: "United States",
      city: "Mountain View"
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
