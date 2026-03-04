require "active_job"
require "active_record"
require "action_dispatch"
require "faraday"
require "ipaddr"
require "json"

require "sentinel_tracker/version"
require "sentinel_tracker/configuration"

module SentinelTracker
  class << self
    ##
    # @return [SentinelTracker::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    ##
    # @yieldparam configuration [SentinelTracker::Configuration]
    # @return [SentinelTracker::Configuration]
    def configure
      yield(configuration)
      configuration
    end

    ##
    # Сбрасывает конфигурацию.
    # @return [SentinelTracker::Configuration]
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

require "sentinel_tracker/engine" if defined?(Rails::Engine)
require_relative "../app/services/sentinel_tracker/initializer_configuration"
require_relative "../app/services/sentinel_tracker/shared/public_ip_guard"
require_relative "../app/services/sentinel_tracker/request_audit/request_context_extractor"
require_relative "../app/services/sentinel_tracker/security_event_enrichment_registry"
require_relative "../app/services/sentinel_tracker/providers/ip_api/provider"
require_relative "../app/services/sentinel_tracker/network_telemetry_registry"
require_relative "../app/services/sentinel_tracker/providers/globalping/provider"
require_relative "../app/services/sentinel_tracker/providers/local_traceroute/command_builder"
require_relative "../app/services/sentinel_tracker/providers/local_traceroute/command_runner"
require_relative "../app/services/sentinel_tracker/providers/local_traceroute/provider"
require_relative "../app/services/sentinel_tracker/resolvers/current_login_resolver"
require_relative "../app/services/sentinel_tracker/resolvers/current_user_id_resolver"
require_relative "../app/services/sentinel_tracker/request_audit/target_matcher"
require_relative "../app/services/sentinel_tracker/security_events/pipeline"
require_relative "../app/services/sentinel_tracker/security_events/metadata_enricher"
require_relative "../app/models/sentinel_tracker/security_event"
require_relative "../app/models/sentinel_tracker/security_event_network_telemetry_result"
require_relative "../app/repositories/sentinel_tracker/security_event_repository"
require_relative "../app/repositories/sentinel_tracker/security_event_network_telemetry_result_repository"
require_relative "../app/use_cases/sentinel_tracker/security_events/create"
require_relative "../app/services/sentinel_tracker/security_events/telemetry_collector"
require_relative "../app/jobs/sentinel_tracker/application_job"
require_relative "../app/jobs/sentinel_tracker/security_events/persist_job"
require_relative "../app/jobs/sentinel_tracker/security_events/collect_telemetry_job"
require_relative "../app/middleware/sentinel_tracker/request_audit_middleware"
