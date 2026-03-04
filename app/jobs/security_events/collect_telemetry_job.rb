module SentinelTracker
  module SecurityEvents
    ##
    # Выполняет сбор network telemetry для уже сохранённого события безопасности.
    class CollectTelemetryJob < ApplicationJob
      queue_as :default

      ##
      # @param security_event_id [Integer]
      # @return [void]
      def perform(security_event_id:)
        telemetry_collector.call(security_event_id: security_event_id)
      end

      private

      ##
      # @return [SentinelTracker::Configuration]
      def configuration
        SentinelTracker.configuration
      end

      ##
      # @return [SentinelTracker::SecurityEvents::TelemetryCollector]
      def telemetry_collector
        SentinelTracker::SecurityEvents::TelemetryCollector.new(
          logger: configuration.logger,
          security_event_repository: security_event_repository,
          security_event_network_telemetry_result_repository: security_event_network_telemetry_result_repository,
          network_telemetry_providers: network_telemetry_providers
        )
      end

      ##
      # @return [SentinelTracker::SecurityEventRepository]
      def security_event_repository
        SentinelTracker::SecurityEventRepository.new(model_class: SentinelTracker::SecurityEvent)
      end

      ##
      # @return [SentinelTracker::SecurityEventNetworkTelemetryResultRepository]
      def security_event_network_telemetry_result_repository
        SentinelTracker::SecurityEventNetworkTelemetryResultRepository.new(
          model_class: SentinelTracker::SecurityEventNetworkTelemetryResult
        )
      end

      ##
      # @return [Array<Object>]
      def network_telemetry_providers
        SentinelTracker::NetworkTelemetryRegistry.build_many(
          configuration: configuration,
          provider_names: configuration.network_telemetry_provider_names
        )
      end
    end
  end
end
