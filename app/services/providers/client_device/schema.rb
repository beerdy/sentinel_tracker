module SentinelTracker
  module Providers
    module ClientDevice
      # Канонический контракт client device enrichment для всех provider-ов роли.
      module Schema
        STRING_FIELDS = %w[
          device_type
          device_vendor
          device_model
          os_name
          os_version
          browser_name
          browser_version
          platform
          timezone
          language
          fingerprint_hash
        ].freeze

        INTEGER_FIELDS = %w[
          screen_width
          screen_height
          hardware_concurrency
          device_memory
          touch_points
        ].freeze

        BOOLEAN_FIELDS = %w[bot].freeze
        PAYLOAD_FIELD = "payload".freeze
        ALL_FIELDS = (STRING_FIELDS + INTEGER_FIELDS + BOOLEAN_FIELDS).freeze

        module_function

        # @return [Hash]
        def empty_result
          ALL_FIELDS.each_with_object({}) do |field, result|
            result[field.to_sym] = nil
          end
        end
      end
    end
  end
end
