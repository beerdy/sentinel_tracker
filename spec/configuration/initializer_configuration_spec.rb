require_relative "../../spec_helper"

RSpec.describe SentinelTracker::InitializerConfiguration do
  subject(:call_initializer_configuration) do
    described_class.new(configuration: configuration, environment: environment).call
  end

  let(:configuration) { SentinelTracker::Configuration.new }
  let(:environment) do
    {
      "SENTINEL_TRACKER_ENABLED" => "true",
      "SENTINEL_TRACKER_TARGET_USER_ID" => "42",
      "SENTINEL_TRACKER_TARGET_LOGIN" => "watch@example.com",
      "SENTINEL_TRACKER_SECURITY_EVENT_ENRICHMENT_PROVIDER" => "ip_api",
      "SENTINEL_TRACKER_IP_API_URL" => "http://ip-api.example.test",
      "SENTINEL_TRACKER_IP_API_OPEN_TIMEOUT" => "3",
      "SENTINEL_TRACKER_IP_API_READ_TIMEOUT" => "4",
      "SENTINEL_TRACKER_CLIENT_DEVICE_ENRICHMENT_PROVIDER" => "user_agent_parser",
      "SENTINEL_TRACKER_USER_AGENT_MAX_LENGTH" => "1800",
      "SENTINEL_TRACKER_CLIENT_DEVICE_MAX_STRING_LENGTH" => "220",
      "SENTINEL_TRACKER_NETWORK_TELEMETRY_PROVIDERS" => "local_traceroute,globalping",
      "SENTINEL_TRACKER_TRACEROUTE_COMMAND_PATH" => "/usr/local/bin/traceroute",
      "SENTINEL_TRACKER_REVERSE_PATH_TIMEOUT_SECONDS" => "20",
      "SENTINEL_TRACKER_REVERSE_PATH_MAX_OUTPUT_LENGTH" => "30000",
      "SENTINEL_TRACKER_GLOBALPING_API_URL" => "https://api.globalping.example.test",
      "SENTINEL_TRACKER_GLOBALPING_OPEN_TIMEOUT" => "5",
      "SENTINEL_TRACKER_GLOBALPING_READ_TIMEOUT" => "6",
      "SENTINEL_TRACKER_GLOBALPING_MEASUREMENT_TYPE" => "mtr",
      "SENTINEL_TRACKER_GLOBALPING_POLL_INTERVAL_SECONDS" => "2",
      "SENTINEL_TRACKER_GLOBALPING_MAX_POLLS" => "11"
    }
  end

  it "применяет base и target matching настройки" do
    call_initializer_configuration

    expect(configuration.enabled).to be(true)
    expect(configuration.target_user_id).to eq(42)
    expect(configuration.target_login).to eq("watch@example.com")
    expect(configuration.user_resolver.call(request: ActionDispatch::Request.new("rack.session" => { user_id: 17 }))).to eq(17)
  end

  it "применяет ip enrichment настройки" do
    call_initializer_configuration

    expect(configuration.security_event_enrichment_provider_name).to eq("ip_api")
    expect(configuration.security_event_enrichment_provider_options).to eq(
      "ip_api" => {
        "api_url" => "http://ip-api.example.test",
        "open_timeout" => 3,
        "read_timeout" => 4
      }
    )
  end

  it "применяет network telemetry настройки" do
    call_initializer_configuration

    expect(configuration.network_telemetry_provider_names).to eq(["local_traceroute", "globalping"])
    expect(configuration.network_telemetry_provider_options).to eq(
      "local_traceroute" => {
        "command_path" => "/usr/local/bin/traceroute",
        "timeout_seconds" => 20,
        "max_output_length" => 30000
      },
      "globalping" => {
        "api_url" => "https://api.globalping.example.test",
        "open_timeout" => 5,
        "read_timeout" => 6,
        "measurement_type" => "mtr",
        "poll_interval_seconds" => 2,
        "max_polls" => 11
      }
    )
  end

  it "применяет client device enrichment настройки" do
    call_initializer_configuration

    expect(configuration.client_device_enrichment_provider_name).to eq("user_agent_parser")
    expect(configuration.client_device_enrichment_provider_options).to eq(
      "user_agent_parser" => {
        "max_user_agent_length" => 1800
      },
      "client_payload" => {
        "max_string_length" => 220
      }
    )
  end
end
