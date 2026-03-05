module SentinelTracker
  ##
  # Репозиторий для записи network telemetry результатов по provider.
  class SecurityEventNetworkTelemetryResultRepository
    ##
    # @return [Class]
    attr_reader :model_class

    ##
    # @param model_class [Class]
    # @return [void]
    def initialize(model_class:)
      @model_class = model_class
    end

    ##
    # @param security_event_id [Integer]
    # @param provider_name [String]
    # @param status [String]
    # @param output [String]
    # @param payload [Hash]
    # @return [SentinelTracker::SecurityEventNetworkTelemetryResult]
    def save_result!(security_event_id:, provider_name:, status:, output:, payload: {})
      record = model_class.find_or_initialize_by(
        security_event_id: security_event_id,
        provider_name: provider_name
      )

      record.status = status
      record.output = output
      record.payload = normalize_payload(payload)
      record.save!
      record
    end

    private

    # @param payload [Object]
    # @return [Hash]
    def normalize_payload(payload)
      return payload if payload.is_a?(Hash)

      {}
    end
  end
end
