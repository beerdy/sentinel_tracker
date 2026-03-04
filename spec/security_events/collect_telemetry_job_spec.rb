require_relative "../../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::CollectTelemetryJob do
  it "делегирует выполнение use case" do
    use_case = instance_double(SentinelTracker::SecurityEvents::TelemetryCollector)
    allow(SentinelTracker::SecurityEvents::TelemetryCollector).to receive(:new).and_return(use_case)
    allow(use_case).to receive(:call)

    described_class.perform_now(security_event_id: 15)

    expect(SentinelTracker::SecurityEvents::TelemetryCollector).to have_received(:new)
    expect(use_case).to have_received(:call).with(security_event_id: 15)
  end
end
