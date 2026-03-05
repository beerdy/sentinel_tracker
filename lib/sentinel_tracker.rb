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
require_relative "../app/services/configuration/initializer_configuration"
require_relative "../app/services/guards/public_ip_guard"
require_relative "../app/services/request_audit/request_context_extractor"
require_relative "../app/services/registries/security_event_enrichment_registry"
require_relative "../app/services/providers/ip_api/provider"
require_relative "../app/services/registries/client_device_enrichment_registry"
require_relative "../app/services/providers/client_device/schema"
require_relative "../app/services/providers/user_agent_parser/provider"
require_relative "../app/services/providers/client_payload/provider"
require_relative "../app/services/registries/network_telemetry_registry"
require_relative "../app/services/providers/globalping/provider"
require_relative "../app/services/providers/local_traceroute/command_builder"
require_relative "../app/services/providers/local_traceroute/command_runner"
require_relative "../app/services/providers/local_traceroute/provider"
require_relative "../app/services/resolvers/current_login_resolver"
require_relative "../app/services/resolvers/current_user_id_resolver"
require_relative "../app/services/request_audit/target_matcher"
require_relative "../app/services/security_events/pipeline"
require_relative "../app/services/security_events/metadata_enricher"
require_relative "../app/services/security_events/client_device_enricher"
require_relative "../app/models/security_event"
require_relative "../app/models/security_event_network_telemetry_result"
require_relative "../app/repositories/security_event_repository"
require_relative "../app/repositories/security_event_network_telemetry_result_repository"
require_relative "../app/use_cases/create"
require_relative "../app/services/security_events/telemetry_collector"
require_relative "../app/jobs/application_job"
require_relative "../app/jobs/security_events/persist_job"
require_relative "../app/jobs/security_events/collect_telemetry_job"
require_relative "../app/middleware/request_audit_middleware"
