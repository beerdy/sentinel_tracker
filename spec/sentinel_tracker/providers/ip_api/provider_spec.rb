require_relative "../../../spec_helper"

RSpec.describe SentinelTracker::Providers::IpApi::Provider do
  subject(:provider) do
    described_class.new(
      connection: connection,
      logger: logger
    )
  end

  let(:connection) { instance_double(Faraday::Connection) }
  let(:logger) { Logger.new(nil) }

  it "возвращает метаданные по публичному ip" do
    response = instance_double(
      Faraday::Response,
      body: {
        "status" => "success",
        "as" => "AS15169 Google LLC",
        "isp" => "Google LLC",
        "proxy" => true,
        "country" => "United States",
        "city" => "Mountain View"
      }
    )

    allow(connection).to receive(:get).with("json/8.8.8.8", "fields" => described_class::FIELDS).and_return(response)

    expect(provider.call(ip: "8.8.8.8")).to eq(
      asn: "AS15169 Google LLC",
      isp: "Google LLC",
      proxy: true,
      country: "United States",
      city: "Mountain View"
    )
  end

  it "не делает внешний запрос для локального ip" do
    allow(connection).to receive(:get)

    expect(provider.call(ip: "127.0.0.1")).to eq({})
    expect(connection).not_to have_received(:get)
  end

  it "возвращает пустой enrichment при ошибке provider" do
    allow(connection).to receive(:get).and_raise(Faraday::Error.new("provider timeout"))

    expect(provider.call(ip: "8.8.8.8")).to eq({})
  end
end
