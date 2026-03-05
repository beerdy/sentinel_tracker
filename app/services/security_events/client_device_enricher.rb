module SentinelTracker
  module SecurityEvents
    ##
    # Enricher device-метаданных security event на базе user-agent.
    class ClientDeviceEnricher
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
        device_attributes = provider.call(
          user_agent: payload[:user_agent],
          client_device_payload: extract_client_device_payload(payload: payload)
        )
        normalized_device_attributes = normalize_device_attributes(device_attributes: device_attributes)
        normalized_provider_payload = normalize_provider_payload(device_attributes: device_attributes)
        return {} if normalized_device_attributes.empty? && normalized_provider_payload.empty?

        client_device_payload = stringify_keys(normalized_device_attributes)
        unless normalized_provider_payload.empty?
          client_device_payload[SentinelTracker::Providers::ClientDevice::Schema::PAYLOAD_FIELD] = stringify_keys(normalized_provider_payload)
        end

        {
          params_json_patch: {
            "client_device" => client_device_payload
          }
        }
      end

      private

      ##
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

      ##
      # @param payload [Hash]
      # @return [Hash, nil]
      def extract_client_device_payload(payload:)
        params = payload[:params]
        return unless params.is_a?(Hash)

        params["client_device"] || params[:client_device]
      end

      ##
      # @param device_attributes [Hash, nil]
      # @return [Hash]
      def normalize_device_attributes(device_attributes:)
        return {} unless device_attributes.is_a?(Hash)

        normalized = SentinelTracker::Providers::ClientDevice::Schema.empty_result
        SentinelTracker::Providers::ClientDevice::Schema::ALL_FIELDS.each do |field|
          normalized[field.to_sym] = fetch_field(device_attributes: device_attributes, field: field)
        end

        return {} unless normalized.values.any? { |value| !value.nil? }

        normalized
      end

      ##
      # @param device_attributes [Hash]
      # @param field [String]
      # @return [Object]
      def fetch_field(device_attributes:, field:)
        symbol_key = field.to_sym
        return device_attributes[symbol_key] if device_attributes.key?(symbol_key)

        device_attributes[field]
      end

      ##
      # @param device_attributes [Hash, nil]
      # @return [Hash]
      def normalize_provider_payload(device_attributes:)
        return {} unless device_attributes.is_a?(Hash)

        payload = fetch_field(
          device_attributes: device_attributes,
          field: SentinelTracker::Providers::ClientDevice::Schema::PAYLOAD_FIELD
        )
        return {} unless payload.is_a?(Hash)

        payload
      end
    end
  end
end
