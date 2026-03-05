require_relative "../../../spec_helper"

RSpec.describe SentinelTracker::Providers::UserAgentParser::Provider do
  subject(:provider) do
    described_class.new(
      max_user_agent_length: 2_000,
      logger: logger
    )
  end

  let(:logger) { Logger.new(nil) }

  it "парсит desktop user agent" do
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "\
                 "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    expect(provider.call(user_agent: user_agent, client_device_payload: nil)).to include(
      device_type: "desktop",
      os_name: "macos",
      os_version: "10.15.7",
      browser_name: "chrome",
      browser_version: "120.0.0.0",
      platform: "macos",
      bot: false
    )
  end

  it "парсит mobile user agent" do
    user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 "\
                 "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    expect(provider.call(user_agent: user_agent, client_device_payload: nil)).to include(
      device_type: "mobile",
      device_vendor: "apple",
      device_model: "iphone",
      os_name: "ios",
      os_version: "17.2",
      browser_name: "safari",
      platform: "ios",
      bot: false
    )
  end

  it "возвращает unknown shape при пустом user agent" do
    expect(provider.call(user_agent: nil, client_device_payload: nil)).to eq(
      device_type: "unknown",
      device_vendor: nil,
      device_model: nil,
      os_name: "unknown",
      os_version: nil,
      browser_name: "unknown",
      browser_version: nil,
      platform: "unknown",
      timezone: nil,
      language: nil,
      fingerprint_hash: nil,
      screen_width: nil,
      screen_height: nil,
      hardware_concurrency: nil,
      device_memory: nil,
      touch_points: nil,
      bot: false,
      payload: {
        provider_name: "user_agent_parser"
      }
    )
  end
end
