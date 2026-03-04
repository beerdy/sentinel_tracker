require_relative "../spec_helper"

RSpec.describe SentinelTracker::SecurityEventNetworkTelemetryResultRepository do
  subject(:repository) { described_class.new(model_class: model_class) }

  let(:model_class) { class_double(SentinelTracker::SecurityEventNetworkTelemetryResult) }
  let(:record) { double("SecurityEventNetworkTelemetryResult") }

  it "создаёт или обновляет per-provider результат" do
    allow(model_class).to receive(:find_or_initialize_by).with(
      security_event_id: 15,
      provider_name: "globalping"
    ).and_return(record)
    allow(record).to receive(:status=)
    allow(record).to receive(:output=)
    allow(record).to receive(:save!)

    result = repository.save_result!(
      security_event_id: 15,
      provider_name: "globalping",
      status: "completed",
      output: "trace"
    )

    expect(record).to have_received(:status=).with("completed")
    expect(record).to have_received(:output=).with("trace")
    expect(record).to have_received(:save!)
    expect(result).to eq(record)
  end
end
