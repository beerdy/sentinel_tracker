module SentinelTracker
  module SecurityEvents
    ##
    # Собирает network telemetry для сохранённого события и обновляет его summary.
    class TelemetryCollector
      ##
      # @return [Logger]
      attr_reader :logger
      ##
      # @return [SentinelTracker::SecurityEventRepository]
      attr_reader :security_event_repository
      ##
      # @return [SentinelTracker::SecurityEventNetworkTelemetryResultRepository]
      attr_reader :security_event_network_telemetry_result_repository
      ##
      # @return [Array<Object>]
      attr_reader :network_telemetry_providers

      ##
      # @param logger [Logger]
      # @param security_event_repository [SentinelTracker::SecurityEventRepository]
      # @param security_event_network_telemetry_result_repository [SentinelTracker::SecurityEventNetworkTelemetryResultRepository]
      # @param network_telemetry_providers [Array<Object>]
      # @return [void]
      def initialize(logger:, security_event_repository:, security_event_network_telemetry_result_repository:, network_telemetry_providers:)
        @logger = logger
        @security_event_repository = security_event_repository
        @security_event_network_telemetry_result_repository = security_event_network_telemetry_result_repository
        @network_telemetry_providers = network_telemetry_providers
      end

      ##
      # @param security_event_id [Integer]
      # @return [void]
      def call(security_event_id:)
        security_event = security_event_repository.find(security_event_id: security_event_id)
        return if security_event.nil?

        results = network_telemetry_providers.map do |network_telemetry_provider|
          run_provider(security_event_id: security_event_id, security_event: security_event, network_telemetry_provider: network_telemetry_provider)
        end

        update_security_event_summary(security_event_id: security_event_id, results: results)
      end

      private

      ##
      # @param security_event_id [Integer]
      # @param result [Hash]
      # @return [void]
      def log_result(security_event_id:, result:)
        logger.info(
          "[sentinel_tracker] network telemetry finished for security_event_id=#{security_event_id} " \
          "status=#{result[:network_telemetry_status]} provider=#{result[:provider_name]}"
        )
      end

      ##
      # @param security_event_id [Integer]
      # @param security_event [SentinelTracker::SecurityEvent]
      # @param network_telemetry_provider [Object]
      # @return [Hash]
      def run_provider(security_event_id:, security_event:, network_telemetry_provider:)
        result = network_telemetry_provider.call(ip: security_event.ip)
        security_event_network_telemetry_result_repository.save_result!(
          security_event_id: security_event_id,
          provider_name: result[:provider_name],
          status: result[:network_telemetry_status],
          output: result[:network_telemetry_output],
          payload: result[:payload]
        )
        log_result(security_event_id: security_event_id, result: result)
        result
      end

      ##
      # @param security_event_id [Integer]
      # @param results [Array<Hash>]
      # @return [void]
      def update_security_event_summary(security_event_id:, results:)
        security_event_repository.update_network_telemetry_summary!(
          security_event_id: security_event_id,
          network_telemetry_status: aggregate_status(results: results),
          network_telemetry_output: aggregate_output(results: results)
        )
      end

      ##
      # @param results [Array<Hash>]
      # @return [String]
      def aggregate_status(results:)
        statuses = results.map { |result| result[:network_telemetry_status] }
        return "completed" if statuses.include?("completed")
        return "failed" if statuses.include?("failed")

        "skipped"
      end

      ##
      # @param results [Array<Hash>]
      # @return [String]
      def aggregate_output(results:)
        results.map do |result|
          "#{result[:provider_name]}: #{result[:network_telemetry_status]}"
        end.join("\n")
      end
    end
  end
end
