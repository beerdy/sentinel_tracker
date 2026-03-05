module SentinelTracker
  ##
  # Реестр provider'ов enrichment client device.
  class ClientDeviceEnrichmentRegistry
    class << self
      ##
      # @param configuration [SentinelTracker::Configuration]
      # @param provider_name [String, nil]
      # @return [Object]
      def build(configuration:, provider_name:)
        normalized_provider_name = normalize_provider_name(provider_name: provider_name)
        provider_builder = provider_builder_for(provider_name: normalized_provider_name)
        provider_builder.call(configuration, provider_options_for(configuration: configuration, provider_name: normalized_provider_name))
      end

      ##
      # @param provider_name [String]
      # @param provider_builder [Proc]
      # @return [void]
      def register(provider_name:, provider_builder:)
        registry[provider_name.to_s] = provider_builder
      end

      private

      ##
      # @param provider_name [String, nil]
      # @return [String]
      def normalize_provider_name(provider_name:)
        value = provider_name.to_s.strip
        raise ArgumentError, "Client device enrichment provider name is empty" if value.empty?

        value
      end

      ##
      # @param provider_name [String]
      # @return [Proc]
      def provider_builder_for(provider_name:)
        provider_builder = registry[provider_name]
        return provider_builder unless provider_builder.nil?

        raise ArgumentError, "Unknown client device enrichment provider: #{provider_name}"
      end

      ##
      # @return [Hash]
      def registry
        @registry ||= {}
      end

      ##
      # @param configuration [SentinelTracker::Configuration]
      # @param provider_name [String]
      # @return [Hash]
      def provider_options_for(configuration:, provider_name:)
        options = configuration.client_device_enrichment_provider_options || {}
        provider_options = options[provider_name]
        return {} if provider_options.nil?

        provider_options
      end
    end
  end
end
