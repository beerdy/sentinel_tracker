module SentinelTracker
  ##
  # Репозиторий для записи событий безопасности.
  class SecurityEventRepository
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
    # @param attributes [Hash]
    # @return [SentinelTracker::SecurityEvent]
    def create!(attributes:)
      model_class.create!(attributes)
    end

    ##
    # @param security_event_id [Integer]
    # @return [SentinelTracker::SecurityEvent, nil]
    def find(security_event_id:)
      model_class.find_by(id: security_event_id)
    end

    ##
    # @param security_event_id [Integer]
    # @param network_telemetry_status [String]
    # @param network_telemetry_output [String]
    # @return [Boolean]
    def update_network_telemetry_summary!(security_event_id:, network_telemetry_status:, network_telemetry_output:)
      security_event = model_class.find(security_event_id)
      security_event.update!(
        network_telemetry_status: network_telemetry_status,
        network_telemetry_output: network_telemetry_output
      )
    end
  end
end
