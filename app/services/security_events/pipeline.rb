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
          attributes.merge!(enricher.call(payload: payload))
        end
      end
    end
  end
end
