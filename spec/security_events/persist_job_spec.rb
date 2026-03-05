require_relative "../../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::PersistJob do
  it "включает client device enricher в pipeline" do
    pipeline = described_class.new.send(:pipeline)
    enrichers = pipeline.enrichers

    expect(enrichers.map(&:class)).to eq(
      [
        SentinelTracker::SecurityEvents::MetadataEnricher,
        SentinelTracker::SecurityEvents::ClientDeviceEnricher
      ]
    )
    expect(enrichers.last.provider).to be_a(SentinelTracker::Providers::UserAgentParser::Provider)
  end
end
