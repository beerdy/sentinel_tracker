require_relative "../../../spec_helper"

RSpec.describe SentinelTracker::Providers::ClientPayload::Provider do
  subject(:provider) do
    described_class.new(
      max_string_length: 50,
      logger: logger
    )
  end

  let(:logger) { Logger.new(nil) }

  it "возвращает нормализованный device payload от фронтенда" do
    payload = {
      "device_type" => "mobile",
      "device_model" => "iPhone 15 Pro",
      "os_name" => "ios",
      "os_version" => "17.4",
      "browser_name" => "safari",
      "browser_version" => "17.4",
      "platform" => "ios",
      "timezone" => "Europe/Moscow",
      "screen_width" => "1179",
      "screen_height" => 2556,
      "hardware_concurrency" => 6,
      "device_memory" => 8,
      "touch_points" => 5,
      "bot" => "false",
      "fingerprint_hash" => "abc123"
    }

    expect(provider.call(user_agent: "Mozilla", client_device_payload: payload)).to eq(
      device_type: "mobile",
      device_vendor: nil,
      device_model: "iPhone 15 Pro",
      os_name: "ios",
      os_version: "17.4",
      browser_name: "safari",
      browser_version: "17.4",
      platform: "ios",
      timezone: "Europe/Moscow",
      language: nil,
      fingerprint_hash: "abc123",
      screen_width: 1179,
      screen_height: 2556,
      hardware_concurrency: 6,
      device_memory: 8,
      touch_points: 5,
      bot: false,
      payload: {
        provider_name: "client_payload",
        user_agent: "Mozilla",
        raw_keys: [
          "bot",
          "browser_name",
          "browser_version",
          "device_memory",
          "device_model",
          "device_type",
          "fingerprint_hash",
          "hardware_concurrency",
          "os_name",
          "os_version",
          "platform",
          "screen_height",
          "screen_width",
          "timezone",
          "touch_points"
        ]
      }
    )
  end

  it "фильтрует неизвестные поля и невалидные типы" do
    payload = {
      "custom_secret" => "drop",
      "screen_width" => "invalid",
      "bot" => "oops"
    }

    expect(provider.call(user_agent: nil, client_device_payload: payload)).to eq({})
  end

  it "возвращает пустой hash, если client_device_payload не hash" do
    expect(provider.call(user_agent: "UA", client_device_payload: "raw")).to eq({})
  end
end
