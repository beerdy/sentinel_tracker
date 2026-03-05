module SentinelTracker
  module Providers
    module ClientPayload
      ##
      # Client device enrichment provider на базе payload, присланного с фронтенда.
      class Provider
        PROVIDER_NAME ||= "client_payload".freeze
        ALLOWED_STRING_FIELDS ||= SentinelTracker::Providers::ClientDevice::Schema::STRING_FIELDS
        ALLOWED_INTEGER_FIELDS ||= SentinelTracker::Providers::ClientDevice::Schema::INTEGER_FIELDS
        MAX_INTEGER_VALUE ||= 1_000_000

        ##
        # @return [Integer]
        attr_reader :max_string_length
        ##
        # @return [Logger]
        attr_reader :logger

        ##
        # @param max_string_length [Integer]
        # @param logger [Logger]
        # @return [void]
        def initialize(max_string_length:, logger:)
          @max_string_length = max_string_length
          @logger = logger
        end

        ##
        # @param user_agent [String, nil]
        # @param client_device_payload [Hash, nil]
        # @return [Hash]
        def call(user_agent:, client_device_payload:)
          payload = normalize_hash(value: client_device_payload)
          return {} if payload.empty?

          result = SentinelTracker::Providers::ClientDevice::Schema.empty_result
          ALLOWED_STRING_FIELDS.each do |field|
            value = normalize_string(payload[field])
            result[field.to_sym] = value
          end

          ALLOWED_INTEGER_FIELDS.each do |field|
            value = normalize_integer(payload[field])
            result[field.to_sym] = value
          end

          result[:bot] = normalize_boolean(payload["bot"])
          return {} unless meaningful_result?(result)

          result.merge(payload: payload_for(user_agent: user_agent, client_device_payload: payload))
        rescue StandardError => error
          logger.warn("[sentinel_tracker] client payload parsing failed: #{error.class}: #{error.message}")
          {}
        end

        ##
        # @return [String]
        def provider_name
          PROVIDER_NAME
        end

        private

        ##
        # @param value [Object]
        # @return [Hash]
        def normalize_hash(value:)
          return value if value.is_a?(Hash)

          {}
        end

        ##
        # @param value [Object]
        # @return [String, nil]
        def normalize_string(value)
          normalized_value = value.to_s.strip
          return nil if normalized_value.empty?

          normalized_value[0...max_string_length]
        end

        ##
        # @param value [Object]
        # @return [Integer, nil]
        def normalize_integer(value)
          return nil if value.nil?

          integer_value = Integer(value)
          return nil if integer_value.negative? || integer_value > MAX_INTEGER_VALUE

          integer_value
        rescue ArgumentError, TypeError
          nil
        end

        ##
        # @param value [Object]
        # @return [Boolean, nil]
        def normalize_boolean(value)
          return value if value == true || value == false
          return true if value.to_s.strip.downcase == "true"
          return false if value.to_s.strip.downcase == "false"

          nil
        end

        ##
        # @param result [Hash]
        # @return [Boolean]
        def meaningful_result?(result)
          result.values.any? { |value| !value.nil? }
        end

        ##
        # @param user_agent [String, nil]
        # @param client_device_payload [Hash]
        # @return [Hash]
        def payload_for(user_agent:, client_device_payload:)
          {
            provider_name: provider_name,
            user_agent: normalize_string(user_agent),
            raw_keys: client_device_payload.keys.map(&:to_s).sort
          }.compact
        end
      end
    end
  end
end

SentinelTracker::ClientDeviceEnrichmentRegistry.register(
  provider_name: SentinelTracker::Providers::ClientPayload::Provider::PROVIDER_NAME,
  provider_builder: lambda do |configuration, provider_options|
    max_string_length = provider_options.fetch("max_string_length", 200).to_i

    SentinelTracker::Providers::ClientPayload::Provider.new(
      max_string_length: max_string_length,
      logger: configuration.logger
    )
  end
)
