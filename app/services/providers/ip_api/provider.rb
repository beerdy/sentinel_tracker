module SentinelTracker
  module Providers
    module IpApi
      ##
      # IP enrichment provider на базе ip-api.com.
      class Provider
        FIELDS = "status,message,as,isp,proxy,country,city".freeze
        PROVIDER_NAME = "ip_api".freeze

        ##
        # @return [Faraday::Connection]
        attr_reader :connection
        ##
        # @return [Logger]
        attr_reader :logger

        ##
        # @param connection [Faraday::Connection]
        # @param logger [Logger]
        # @return [void]
        def initialize(connection:, logger:)
          @connection = connection
          @logger = logger
        end

        ##
        # @param ip [String, nil]
        # @return [Hash]
        def call(ip:)
          return {} unless SentinelTracker::Shared::PublicIpGuard.public?(ip: ip)

          response = connection.get("json/#{ip}", "fields" => FIELDS)
          normalize_body(response.body)
        rescue StandardError => error
          logger.warn("[sentinel_tracker] ip enrichment failed for #{ip}: #{error.class}: #{error.message}")
          {}
        end

        ##
        # @return [String]
        def provider_name
          PROVIDER_NAME
        end

        private

        ##
        # @param body [Hash, String]
        # @return [Hash]
        def normalize_body(body)
          payload = body.is_a?(Hash) ? body : JSON.parse(body.to_s)
          return {} unless payload["status"] == "success"

          {
            asn: payload["as"],
            isp: payload["isp"],
            proxy: payload["proxy"],
            country: payload["country"],
            city: payload["city"],
            payload: {
              provider_name: provider_name,
              response_status: payload["status"],
              response_message: payload["message"]
            }.compact
          }
        end
      end
    end
  end
end

SentinelTracker::SecurityEventEnrichmentRegistry.register(
  provider_name: SentinelTracker::Providers::IpApi::Provider::PROVIDER_NAME,
  provider_builder: lambda do |configuration, provider_options|
    api_url = provider_options.fetch("api_url", "http://ip-api.com")
    open_timeout = provider_options.fetch("open_timeout", 2)
    read_timeout = provider_options.fetch("read_timeout", 2)

    connection = Faraday.new(url: api_url) do |faraday|
      faraday.options.open_timeout = open_timeout
      faraday.options.timeout = read_timeout
      faraday.adapter Faraday.default_adapter
    end

    SentinelTracker::Providers::IpApi::Provider.new(
      connection: connection,
      logger: configuration.logger
    )
  end
)
