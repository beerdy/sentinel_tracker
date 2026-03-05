module SentinelTracker
  module SecurityEvents
    ##
    # Асинхронно обрабатывает захваченный request context.
    class PersistJob < ApplicationJob
      queue_as :sentinel_tracker

      ##
      # @param payload [Hash]
      # @return [void]
      def perform(payload)
        security_event = create_use_case.call(payload: payload)
        enqueue_network_telemetry(security_event)
      end

      private

      ##
      # @return [SentinelTracker::Configuration]
      def configuration
        SentinelTracker.configuration
      end

      ##
      # @return [SentinelTracker::SecurityEvents::Create]
      def create_use_case
        SentinelTracker::SecurityEvents::Create.new(
          logger: configuration.logger,
          security_event_repository: security_event_repository,
          pipeline: pipeline
        )
      end

      ##
      # @return [SentinelTracker::SecurityEventRepository]
      def security_event_repository
        SentinelTracker::SecurityEventRepository.new(model_class: SentinelTracker::SecurityEvent)
      end

      ##
      # @return [SentinelTracker::SecurityEvents::Pipeline]
      def pipeline
        SentinelTracker::SecurityEvents::Pipeline.new(enrichers: [metadata_enricher, client_device_enricher])
      end

      ##
      # @return [SentinelTracker::SecurityEvents::MetadataEnricher]
      def metadata_enricher
        SentinelTracker::SecurityEvents::MetadataEnricher.new(provider: security_event_enrichment_provider)
      end

      ##
      # @return [SentinelTracker::SecurityEvents::ClientDeviceEnricher]
      def client_device_enricher
        SentinelTracker::SecurityEvents::ClientDeviceEnricher.new(provider: client_device_enrichment_provider)
      end

      ##
      # @return [Object]
      def security_event_enrichment_provider
        SentinelTracker::SecurityEventEnrichmentRegistry.build(
          configuration: configuration,
          provider_name: configuration.security_event_enrichment_provider_name
        )
      end

      ##
      # @return [Object]
      def client_device_enrichment_provider
        SentinelTracker::ClientDeviceEnrichmentRegistry.build(
          configuration: configuration,
          provider_name: configuration.client_device_enrichment_provider_name
        )
      end

      ##
      # @param security_event [SentinelTracker::SecurityEvent, Hash]
      # @return [void]
      def enqueue_network_telemetry(security_event)
        return unless security_event.is_a?(SentinelTracker::SecurityEvent)

        SentinelTracker::SecurityEvents::CollectTelemetryJob.perform_later(security_event_id: security_event.id)
      end
    end
  end
end
