module SentinelTracker
  ##
  # Реестр provider'ов network telemetry.
  class NetworkTelemetryRegistry
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
      # @param configuration [SentinelTracker::Configuration]
      # @param provider_names [Array<String>, nil]
      # @return [Array<Object>]
      def build_many(configuration:, provider_names:)
        normalize_provider_names(provider_names: provider_names).map do |provider_name|
          build(configuration: configuration, provider_name: provider_name)
        end
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
        raise ArgumentError, "Network telemetry provider name is empty" if value.empty?

        value
      end

      ##
      # @param provider_name [String]
      # @return [Proc]
      def provider_builder_for(provider_name:)
        provider_builder = registry[provider_name]
        return provider_builder unless provider_builder.nil?

        raise ArgumentError, "Unknown network telemetry provider: #{provider_name}"
      end

      ##
      # @param configuration [SentinelTracker::Configuration]
      # @param provider_name [String]
      # @return [Hash]
      def provider_options_for(configuration:, provider_name:)
        options = configuration.network_telemetry_provider_options || {}
        provider_options = options[provider_name]
        return {} if provider_options.nil?

        provider_options
      end

      ##
      # @return [Hash]
      def registry
        @registry ||= {}
      end

      ##
      # @param provider_names [Array<String>, nil]
      # @return [Array<String>]
      def normalize_provider_names(provider_names:)
        values = Array(provider_names).map do |provider_name|
          provider_name.to_s.strip
        end.reject(&:empty?).uniq
        raise ArgumentError, "Network telemetry providers list is empty" if values.empty?

        values.uniq
      end
    end
  end
end
