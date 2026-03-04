module SentinelTracker
  module SecurityEvents
    ##
    # Enricher метаданных security event.
    class MetadataEnricher
      ##
      # @return [Object]
      attr_reader :provider

      ##
      # @param provider [Object]
      # @return [void]
      def initialize(provider:)
        @provider = provider
      end

      ##
      # @param payload [Hash]
      # @return [Hash]
      def call(payload:)
        enrichment_attributes = provider.call(ip: payload[:ip])

        {
          asn: enrichment_attributes[:asn],
          isp: enrichment_attributes[:isp],
          proxy: enrichment_attributes[:proxy],
          country: enrichment_attributes[:country],
          city: enrichment_attributes[:city]
        }
      end
    end
  end
end
