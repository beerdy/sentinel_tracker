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
        result = {
          asn: enrichment_attributes[:asn],
          isp: enrichment_attributes[:isp],
          proxy: enrichment_attributes[:proxy],
          country: enrichment_attributes[:country],
          city: enrichment_attributes[:city]
        }
        provider_payload = enrichment_attributes[:payload]
        return result unless provider_payload.is_a?(Hash) && !provider_payload.empty?

        result.merge(
          params_json_patch: {
            "security_event_enrichment" => {
              "provider_name" => provider.provider_name,
              "payload" => stringify_keys(provider_payload)
            }
          }
        )
      end

      private

      # @param value [Object]
      # @return [Object]
      def stringify_keys(value)
        if value.is_a?(Hash)
          value.each_with_object({}) do |(key, nested_value), result|
            result[key.to_s] = stringify_keys(nested_value)
          end
        elsif value.is_a?(Array)
          value.map { |nested_value| stringify_keys(nested_value) }
        else
          value
        end
      end
    end
  end
end
