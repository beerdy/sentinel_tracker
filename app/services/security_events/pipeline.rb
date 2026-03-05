module SentinelTracker
  module SecurityEvents
    ##
    # Линейный orchestration pipeline для enrichment шагов security event.
    class Pipeline
      ##
      # @return [Array<Object>]
      attr_reader :enrichers

      ##
      # @param enrichers [Array<Object>]
      # @return [void]
      def initialize(enrichers:)
        @enrichers = enrichers
      end

      ##
      # @param payload [Hash]
      # @return [Hash]
      def call(payload:)
        enrichers.each_with_object({}) do |enricher, attributes|
          attributes.merge!(deep_merge_hash(attributes, enricher.call(payload: payload)))
        end
      end

      private

      # @param base [Hash]
      # @param patch [Hash]
      # @return [Hash]
      def deep_merge_hash(base, patch)
        return base unless patch.is_a?(Hash)

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
    end
  end
end
