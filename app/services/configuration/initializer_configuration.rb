module SentinelTracker
  ##
  # Применяет каноническую ENV-конфигурацию к SentinelTracker::Configuration.
  class InitializerConfiguration
    ##
    # @return [SentinelTracker::Configuration]
    attr_reader :configuration
    ##
    # @return [#fetch, #[]]
    attr_reader :environment

    ##
    # @param configuration [SentinelTracker::Configuration]
    # @param environment [#fetch, #[]]
    # @return [void]
    def initialize(configuration:, environment:)
      @configuration = configuration
      @environment = environment
    end

    ##
    # @return [SentinelTracker::Configuration]
    def call
      apply_base_settings
      apply_target_matching_settings
      apply_security_event_enrichment_settings
      apply_client_device_enrichment_settings
      apply_network_telemetry_settings
      configuration
    end

    private

    ##
    # @return [void]
    def apply_base_settings
      configuration.enabled = environment["SENTINEL_TRACKER_ENABLED"] == "true"
    end

    ##
    # @return [void]
    def apply_target_matching_settings
      configuration.target_user_id = normalized_target_user_id
      configuration.target_login = environment["SENTINEL_TRACKER_TARGET_LOGIN"]
      configuration.user_resolver = SentinelTracker::Resolvers::CurrentUserIdResolver.new
      configuration.login_resolver = SentinelTracker::Resolvers::CurrentLoginResolver.new
    end

    ##
    # @return [void]
    def apply_security_event_enrichment_settings
      configuration.security_event_enrichment_provider_name = environment.fetch("SENTINEL_TRACKER_SECURITY_EVENT_ENRICHMENT_PROVIDER", "ip_api")
      configuration.security_event_enrichment_provider_options = build_security_event_enrichment_provider_options
    end

    ##
    # @return [void]
    def apply_network_telemetry_settings
      configuration.network_telemetry_provider_names = network_telemetry_provider_names
      configuration.network_telemetry_provider_options = build_network_telemetry_provider_options
    end

    ##
    # @return [void]
    def apply_client_device_enrichment_settings
      configuration.client_device_enrichment_provider_name = environment.fetch("SENTINEL_TRACKER_CLIENT_DEVICE_ENRICHMENT_PROVIDER", "user_agent_parser")
      configuration.client_device_enrichment_provider_options = build_client_device_enrichment_provider_options
    end

    ##
    # @return [Array<String>]
    def network_telemetry_provider_names
      environment.fetch("SENTINEL_TRACKER_NETWORK_TELEMETRY_PROVIDERS", "local_traceroute,globalping").split(",").map(&:strip).reject(&:empty?)
    end

    ##
    # @return [Hash]
    def build_security_event_enrichment_provider_options
      {
        "ip_api" => {
          "api_url" => environment.fetch("SENTINEL_TRACKER_IP_API_URL", "http://ip-api.com"),
          "open_timeout" => environment.fetch("SENTINEL_TRACKER_IP_API_OPEN_TIMEOUT", "2").to_i,
          "read_timeout" => environment.fetch("SENTINEL_TRACKER_IP_API_READ_TIMEOUT", "2").to_i
        }
      }
    end

    ##
    # @return [Hash]
    def build_network_telemetry_provider_options
      {
        "local_traceroute" => {
          "command_path" => environment.fetch("SENTINEL_TRACKER_TRACEROUTE_COMMAND_PATH", "/usr/sbin/traceroute"),
          "timeout_seconds" => environment.fetch("SENTINEL_TRACKER_REVERSE_PATH_TIMEOUT_SECONDS", "15").to_i,
          "max_output_length" => environment.fetch("SENTINEL_TRACKER_REVERSE_PATH_MAX_OUTPUT_LENGTH", "20000").to_i
        },
        "globalping" => {
          "api_url" => environment.fetch("SENTINEL_TRACKER_GLOBALPING_API_URL", "https://api.globalping.io"),
          "open_timeout" => environment.fetch("SENTINEL_TRACKER_GLOBALPING_OPEN_TIMEOUT", "2").to_i,
          "read_timeout" => environment.fetch("SENTINEL_TRACKER_GLOBALPING_READ_TIMEOUT", "2").to_i,
          "measurement_type" => environment.fetch("SENTINEL_TRACKER_GLOBALPING_MEASUREMENT_TYPE", "traceroute"),
          "poll_interval_seconds" => environment.fetch("SENTINEL_TRACKER_GLOBALPING_POLL_INTERVAL_SECONDS", "1").to_i,
          "max_polls" => environment.fetch("SENTINEL_TRACKER_GLOBALPING_MAX_POLLS", "10").to_i
        }
      }
    end

    ##
    # @return [Hash]
    def build_client_device_enrichment_provider_options
      {
        "user_agent_parser" => {
          "max_user_agent_length" => environment.fetch("SENTINEL_TRACKER_USER_AGENT_MAX_LENGTH", "2000").to_i
        },
        "client_payload" => {
          "max_string_length" => environment.fetch("SENTINEL_TRACKER_CLIENT_DEVICE_MAX_STRING_LENGTH", "200").to_i
        }
      }
    end

    ##
    # @return [Integer, nil]
    def normalized_target_user_id
      value = environment["SENTINEL_TRACKER_TARGET_USER_ID"]
      return if value.nil?

      normalized_value = value.to_s.strip
      return if normalized_value.empty?

      normalized_value.to_i
    end
  end
end
