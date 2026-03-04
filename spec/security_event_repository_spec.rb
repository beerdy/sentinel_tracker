require_relative "../spec_helper"

RSpec.describe SentinelTracker::SecurityEventRepository do
  subject(:repository) { described_class.new(model_class: model_class) }

  let(:model_class) { class_double(SentinelTracker::SecurityEvent) }

  it "создаёт событие через model class" do
    allow(model_class).to receive(:create!).with(request_path: "/profile").and_return(:record)

    expect(repository.create!(attributes: { request_path: "/profile" })).to eq(:record)
  end

  it "ищет событие по id" do
    allow(model_class).to receive(:find_by).with(id: 15).and_return(:record)

    expect(repository.find(security_event_id: 15)).to eq(:record)
  end

  it "обновляет summary network telemetry" do
    security_event = instance_double(SentinelTracker::SecurityEvent)
    allow(model_class).to receive(:find).with(15).and_return(security_event)
    allow(security_event).to receive(:update!)

    repository.update_network_telemetry_summary!(
      security_event_id: 15,
      network_telemetry_status: "completed",
      network_telemetry_output: "globalping: completed"
    )

    expect(security_event).to have_received(:update!).with(
      network_telemetry_status: "completed",
      network_telemetry_output: "globalping: completed"
    )
  end
end
