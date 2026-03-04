require "logger"

module SentinelTracker
  ##
  # Конфигурация gem-а sentinel_tracker.
  class Configuration
    ##
    # @return [Boolean]
    attr_accessor :enabled
    ##
    # @return [Integer, nil]
    attr_accessor :target_user_id
    ##
    # @return [String, nil]
    attr_accessor :target_login
    ##
    # @return [Object]
    attr_accessor :user_resolver
    ##
    # @return [Object]
    attr_accessor :login_resolver
    ##
    # @return [Logger]
    attr_accessor :logger
    ##
    # @return [String]
    attr_accessor :security_event_enrichment_provider_name
    ##
    # @return [Hash]
    attr_accessor :security_event_enrichment_provider_options
    ##
    # @return [Array<String>]
    attr_accessor :network_telemetry_provider_names
    ##
    # @return [Hash]
    attr_accessor :network_telemetry_provider_options

    ##
    # Инициализирует конфигурацию значениями по умолчанию.
    # @return [void]
    def initialize
      apply_base_defaults
      apply_target_matching_defaults
      apply_security_event_enrichment_defaults
      apply_network_telemetry_defaults
    end

    ##
    # Возвращает нормализованный login из конфигурации.
    # @return [String, nil]
    def normalized_target_login
      normalize_login(target_login)
    end

    private

    ##
    # @return [void]
    def apply_base_defaults
      @enabled = false
      @logger = Logger.new($stdout)
    end

    ##
    # @return [void]
    def apply_target_matching_defaults
      @target_user_id = nil
      @target_login = nil
      @user_resolver = build_user_resolver
      @login_resolver = build_login_resolver
    end

    ##
    # @return [void]
    def apply_security_event_enrichment_defaults
      @security_event_enrichment_provider_name = "ip_api"
      @security_event_enrichment_provider_options = {}
    end

    ##
    # @return [void]
    def apply_network_telemetry_defaults
      @network_telemetry_provider_names = ["local_traceroute", "globalping"]
      @network_telemetry_provider_options = {}
    end

    ##
    # @return [Object]
    def build_user_resolver
      SentinelTracker::Resolvers::CurrentUserIdResolver.new
    end

    ##
    # @return [Object]
    def build_login_resolver
      SentinelTracker::Resolvers::CurrentLoginResolver.new
    end

    ##
    # @param login [String, nil]
    # @return [String, nil]
    def normalize_login(login)
      return if login.nil?

      normalized_login = login.to_s.strip.downcase
      return if normalized_login.empty?

      normalized_login
    end
  end
end
