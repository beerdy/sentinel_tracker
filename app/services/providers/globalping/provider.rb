module SentinelTracker
  module Providers
    module Globalping
      ##
      # Network telemetry provider на базе Globalping REST API.
      class Provider
        PROVIDER_NAME = "globalping".freeze
        ##
        # @return [Faraday::Connection]
        attr_reader :connection
        ##
        # @return [Logger]
        attr_reader :logger
        ##
        # @return [String]
        attr_reader :measurement_type
        ##
        # @return [Integer]
        attr_reader :poll_interval_seconds
        ##
        # @return [Integer]
        attr_reader :max_polls

        ##
        # @param connection [Faraday::Connection]
        # @param logger [Logger]
        # @param measurement_type [String]
        # @param poll_interval_seconds [Integer]
        # @param max_polls [Integer]
        # @return [void]
        def initialize(connection:, logger:, measurement_type:, poll_interval_seconds:, max_polls:)
          @connection = connection
          @logger = logger
          @measurement_type = measurement_type
          @poll_interval_seconds = poll_interval_seconds
          @max_polls = max_polls
        end

        ##
        # @param ip [String, nil]
        # @return [Hash]
        def call(ip:)
          return skipped_result("globalping network telemetry skipped for non-public ip") unless SentinelTracker::Shared::PublicIpGuard.public?(ip: ip)

          measurement_id = create_measurement(ip: ip)
          return failed_result("globalping measurement id missing") if measurement_id.nil?

          poll_measurement(measurement_id: measurement_id)
        rescue StandardError => error
          logger.warn("[sentinel_tracker] globalping failed for #{ip}: #{error.class}: #{error.message}")
          failed_result("#{error.class}: #{error.message}")
        end

        ##
        # @return [String]
        def provider_name
          PROVIDER_NAME
        end

        private

        ##
        # @param ip [String]
        # @return [String, nil]
        def create_measurement(ip:)
          response = connection.post("v1/measurements", create_payload(ip: ip))
          body = normalize_body(response.body)
          raise_api_error(body)

          body["id"]
        end

        ##
        # @param measurement_id [String]
        # @return [Hash]
        def poll_measurement(measurement_id:)
          max_polls.times do |index|
            response = connection.get("v1/measurements/#{measurement_id}")
            body = normalize_body(response.body)
            raise_api_error(body)

            status = body["status"].to_s
            return completed_result(body) unless in_progress_status?(status)

            sleep(poll_interval_seconds) if index < max_polls - 1
          end

          failed_result("globalping polling timeout after #{max_polls} polls")
        end

        ##
        # @param ip [String]
        # @return [Hash]
        def create_payload(ip:)
          {
            "target" => ip,
            "type" => measurement_type,
            "limit" => 1,
            "locations" => []
          }
        end

        ##
        # @param status [String]
        # @return [Boolean]
        def in_progress_status?(status)
          %w[in-progress in_progress].include?(status)
        end

        ##
        # @param body [Hash]
        # @return [Hash]
        def completed_result(body)
          raw_output = extract_raw_output(body)
          return failed_result("globalping results missing rawOutput") if raw_output.nil?

          {
            network_telemetry_status: "completed",
            network_telemetry_output: raw_output,
            provider_name: provider_name
          }
        end

        ##
        # @param body [Hash]
        # @return [String, nil]
        def extract_raw_output(body)
          results = body["results"]
          return if !results.is_a?(Array) || results.empty?

          raw_outputs = results.each_with_object([]) do |result_entry, output|
            result_payload = result_entry["result"]
            next if !result_payload.is_a?(Hash) || result_payload["rawOutput"].to_s.empty?

            output << result_payload["rawOutput"]
          end

          return if raw_outputs.empty?

          raw_outputs.join("\n\n")
        end

        ##
        # @param body [Hash]
        # @return [void]
        def raise_api_error(body)
          return unless body["error"]

          message = body["error"]["message"] || body["error"].to_s
          raise StandardError, "globalping api error: #{message}"
        end

        ##
        # @param body [Hash, String]
        # @return [Hash]
        def normalize_body(body)
          body.is_a?(Hash) ? body : JSON.parse(body.to_s)
        end

        ##
        # @param message [String]
        # @return [Hash]
        def skipped_result(message)
          {
            network_telemetry_status: "skipped",
            network_telemetry_output: message,
            provider_name: provider_name
          }
        end

        ##
        # @param message [String]
        # @return [Hash]
        def failed_result(message)
          {
            network_telemetry_status: "failed",
            network_telemetry_output: message,
            provider_name: provider_name
          }
        end
      end
    end
  end
end

SentinelTracker::NetworkTelemetryRegistry.register(
  provider_name: SentinelTracker::Providers::Globalping::Provider::PROVIDER_NAME,
  provider_builder: lambda do |configuration, provider_options|
    api_url = provider_options.fetch("api_url", "https://api.globalping.io")
    open_timeout = provider_options.fetch("open_timeout", 2)
    read_timeout = provider_options.fetch("read_timeout", 2)

    connection = Faraday.new(url: api_url) do |faraday|
      faraday.options.open_timeout = open_timeout
      faraday.options.timeout = read_timeout
      faraday.adapter Faraday.default_adapter
    end

    SentinelTracker::Providers::Globalping::Provider.new(
      connection: connection,
      logger: configuration.logger,
      measurement_type: provider_options.fetch("measurement_type", "traceroute"),
      poll_interval_seconds: provider_options.fetch("poll_interval_seconds", 1),
      max_polls: provider_options.fetch("max_polls", 10)
    )
  end
)
