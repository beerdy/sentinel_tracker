require_relative "../../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::Pipeline do
  subject(:pipeline) { described_class.new(enrichers: [first_enricher, second_enricher]) }

  let(:first_enricher) { instance_double("FirstEnricher") }
  let(:second_enricher) { instance_double("SecondEnricher") }
  let(:payload) { { ip: "8.8.8.8" } }

  it "линейно объединяет результаты всех enrichers" do
    allow(first_enricher).to receive(:call).with(payload: payload).and_return(asn: "AS15169", isp: "Google LLC")
    allow(second_enricher).to receive(:call).with(payload: payload).and_return(proxy: true, country: "United States")

    expect(pipeline.call(payload: payload)).to eq(
      asn: "AS15169",
      isp: "Google LLC",
      proxy: true,
      country: "United States"
    )
  end

  it "глубоко объединяет вложенные hash поля" do
    allow(first_enricher).to receive(:call).with(payload: payload).and_return(
      params_json_patch: { "security_event_enrichment" => { "provider_name" => "ip_api" } }
    )
    allow(second_enricher).to receive(:call).with(payload: payload).and_return(
      params_json_patch: { "client_device" => { "device_type" => "desktop" } }
    )

    expect(pipeline.call(payload: payload)).to eq(
      params_json_patch: {
        "security_event_enrichment" => { "provider_name" => "ip_api" },
        "client_device" => { "device_type" => "desktop" }
      }
    )
  end
end
