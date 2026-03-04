module SentinelTracker
  ##
  # AR-модель результата network telemetry для конкретного provider.
  class SecurityEventNetworkTelemetryResult < ActiveRecord::Base
    self.table_name = "security_event_network_telemetry_results"
  end
end
