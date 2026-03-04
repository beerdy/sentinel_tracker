module SentinelTracker
  ##
  # AR-модель события безопасности.
  class SecurityEvent < ActiveRecord::Base
    self.table_name = "security_events"
  end
end
