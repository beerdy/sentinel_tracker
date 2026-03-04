module SentinelTracker
  module SecurityEvents
    ##
    # Use case создания события безопасности.
    class Create
      ##
      # @return [Logger]
      attr_reader :logger
      ##
      # @return [SentinelTracker::SecurityEventRepository]
      attr_reader :security_event_repository
      ##
      # @return [SentinelTracker::SecurityEvents::Pipeline]
      attr_reader :pipeline

      ##
      # @param logger [Logger]
      # @param security_event_repository [SentinelTracker::SecurityEventRepository]
      # @param pipeline [SentinelTracker::SecurityEvents::Pipeline]
      # @return [void]
      def initialize(logger:, security_event_repository:, pipeline:)
        @logger = logger
        @security_event_repository = security_event_repository
        @pipeline = pipeline
      end

      ##
      # @param payload [Hash]
      # @return [SentinelTracker::SecurityEvent, Hash]
      def call(payload:)
        return payload unless persistence_available?

        security_event_repository.create!(attributes: build_attributes(payload))
      end

      private

      ##
      # @param payload [Hash]
      # @return [Hash]
      def build_attributes(payload)
        {
          target_user_id: payload[:target_user_id],
          target_login: payload[:target_login],
          request_uuid: payload[:request_uuid],
          request_method: payload[:request_method],
          request_path: payload[:request_path],
          ip: payload[:ip],
          x_forwarded_for: payload[:x_forwarded_for],
          user_agent: payload[:user_agent],
          params_json: payload[:params],
          network_telemetry_status: "pending"
        }.merge(pipeline.call(payload: payload))
      end

      ##
      # @return [Boolean]
      def persistence_available?
        return false unless defined?(ActiveRecord::Base)
        return false unless SentinelTracker::SecurityEvent.table_exists?

        true
      rescue StandardError => error
        logger.warn("[sentinel_tracker] persistence unavailable: #{error.class}: #{error.message}")
        false
      end
    end
  end
end
