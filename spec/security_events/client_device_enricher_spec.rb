require_relative "../../spec_helper"

RSpec.describe SentinelTracker::SecurityEvents::ClientDeviceEnricher do
  subject(:enricher) { described_class.new(provider: provider) }

  let(:provider) { instance_double(SentinelTracker::Providers::UserAgentParser::Provider) }

  it "упаковывает device metadata в params_json_patch.client_device" do
    allow(provider).to receive(:call).with(
      user_agent: "RSpec",
      client_device_payload: nil
    ).and_return(
      device_type: "desktop",
      os_name: "linux",
      browser_name: "firefox",
      payload: { provider_name: "user_agent_parser" }
    )

    expect(enricher.call(payload: { user_agent: "RSpec" })).to eq(
      params_json_patch: {
        "client_device" => {
          "device_type" => "desktop",
          "device_vendor" => nil,
          "device_model" => nil,
          "os_name" => "linux",
          "os_version" => nil,
          "browser_name" => "firefox",
          "browser_version" => nil,
          "platform" => nil,
          "timezone" => nil,
          "language" => nil,
          "fingerprint_hash" => nil,
          "screen_width" => nil,
          "screen_height" => nil,
          "hardware_concurrency" => nil,
          "device_memory" => nil,
          "touch_points" => nil,
          "bot" => nil,
          "payload" => {
            "provider_name" => "user_agent_parser"
          }
        }
      }
    )
  end

  it "возвращает пустой hash, если provider вернул пустой ответ" do
    allow(provider).to receive(:call).with(
      user_agent: nil,
      client_device_payload: nil
    ).and_return({})

    expect(enricher.call(payload: { user_agent: nil })).to eq({})
  end

  it "прокидывает client_device payload из params в provider" do
    allow(provider).to receive(:call).with(
      user_agent: "RSpec",
      client_device_payload: { "platform" => "ios" }
    ).and_return({})

    enricher.call(payload: { user_agent: "RSpec", params: { "client_device" => { "platform" => "ios" } } })

    expect(provider).to have_received(:call).with(
      user_agent: "RSpec",
      client_device_payload: { "platform" => "ios" }
    )
  end

  it "отбрасывает поля вне канонического контракта" do
    allow(provider).to receive(:call).with(
      user_agent: "RSpec",
      client_device_payload: nil
    ).and_return(
      device_type: "desktop",
      payload: { source: "client_payload" },
      extra_flag: "unexpected"
    )

    result = enricher.call(payload: { user_agent: "RSpec" })

    expect(result[:params_json_patch]["client_device"]["payload"]).to eq({ "source" => "client_payload" })
    expect(result[:params_json_patch]["client_device"]).not_to have_key("extra_flag")
  end
end
