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
        enrichment_attributes = pipeline.call(payload: payload)
        params_json_patch = enrichment_attributes.delete(:params_json_patch)

        {
          target_user_id: payload[:target_user_id],
          target_login: payload[:target_login],
          request_uuid: payload[:request_uuid],
          request_method: payload[:request_method],
          request_path: payload[:request_path],
          ip: payload[:ip],
          x_forwarded_for: payload[:x_forwarded_for],
          user_agent: payload[:user_agent],
          params_json: build_params_json(payload_params: payload[:params], params_json_patch: params_json_patch),
          network_telemetry_status: "pending"
        }.merge(enrichment_attributes)
      end

      ##
      # @param payload_params [Hash, nil]
      # @param params_json_patch [Hash, nil]
      # @return [Hash]
      def build_params_json(payload_params:, params_json_patch:)
        base = payload_params.is_a?(Hash) ? payload_params : {}
        return base unless params_json_patch.is_a?(Hash)

        deep_merge_hash(base, params_json_patch)
      end

      ##
      # @param base [Hash]
      # @param patch [Hash]
      # @return [Hash]
      def deep_merge_hash(base, patch)
        base.each_with_object({}) { |(key, value), result| result[key] = value }.tap do |result|
          patch.each do |key, value|
            if result[key].is_a?(Hash) && value.is_a?(Hash)
              result[key] = deep_merge_hash(result[key], value)
            else
              result[key] = value
            end
          end
        end
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
