module SentinelTracker
  module Providers
    module UserAgentParser
      ##
      # Client device enrichment provider на базе user-agent строки.
      class Provider
        PROVIDER_NAME = "user_agent_parser".freeze
        UNKNOWN = "unknown".freeze

        ##
        # @return [Integer]
        attr_reader :max_user_agent_length
        ##
        # @return [Logger]
        attr_reader :logger

        ##
        # @param max_user_agent_length [Integer]
        # @param logger [Logger]
        # @return [void]
        def initialize(max_user_agent_length:, logger:)
          @max_user_agent_length = max_user_agent_length
          @logger = logger
        end

        ##
        # @param user_agent [String, nil]
        # @param client_device_payload [Hash, nil]
        # @return [Hash]
        def call(user_agent:, client_device_payload: nil)
          normalized_user_agent = normalize_user_agent(user_agent)
          return unknown_result if normalized_user_agent.empty?

          device_type = detect_device_type(user_agent: normalized_user_agent)
          browser_name, browser_version = detect_browser(user_agent: normalized_user_agent)
          os_name, os_version = detect_os(user_agent: normalized_user_agent)
          device_vendor, device_model = detect_device(user_agent: normalized_user_agent)

          SentinelTracker::Providers::ClientDevice::Schema.empty_result.merge(
            device_type: device_type,
            device_vendor: device_vendor,
            device_model: device_model,
            os_name: os_name,
            os_version: os_version,
            browser_name: browser_name,
            browser_version: browser_version,
            platform: detect_platform(user_agent: normalized_user_agent),
            bot: device_type == "bot",
            payload: payload_for(user_agent: normalized_user_agent)
          )
        rescue StandardError => error
          logger.warn("[sentinel_tracker] user agent parsing failed: #{error.class}: #{error.message}")
          unknown_result
        end

        ##
        # @return [String]
        def provider_name
          PROVIDER_NAME
        end

        private

        ##
        # @param user_agent [String, nil]
        # @return [String]
        def normalize_user_agent(user_agent)
          user_agent.to_s[0...max_user_agent_length]
        end

        ##
        # @param user_agent [String]
        # @return [String]
        def detect_device_type(user_agent:)
          return "bot" if user_agent.match?(/bot|spider|crawler|curl|wget|httpclient|python-requests|okhttp/i)
          return "tablet" if user_agent.match?(/ipad|tablet|kindle|playbook|sm-t/i)
          return "mobile" if user_agent.match?(/mobile|iphone|android|windows phone|iemobile/i)

          "desktop"
        end

        ##
        # @param user_agent [String]
        # @return [Array<String, String, nil>]
        def detect_browser(user_agent:)
          match = user_agent.match(/Edg\/([\d\.]+)/i)
          return ["edge", match[1]] if match

          match = user_agent.match(/OPR\/([\d\.]+)/i)
          return ["opera", match[1]] if match

          match = user_agent.match(/(Chrome|CriOS)\/([\d\.]+)/i)
          return ["chrome", match[2]] if match

          match = user_agent.match(/(Firefox|FxiOS)\/([\d\.]+)/i)
          return ["firefox", match[2]] if match

          match = user_agent.match(/Version\/([\d\.]+).*Safari/i)
          return ["safari", match[1]] if match

          [UNKNOWN, nil]
        end

        ##
        # @param user_agent [String]
        # @return [Array<String, String, nil>]
        def detect_os(user_agent:)
          match = user_agent.match(/Windows NT ([\d\.]+)/i)
          return ["windows", match[1]] if match

          match = user_agent.match(/Android ([\d\.]+)/i)
          return ["android", match[1]] if match

          match = user_agent.match(/iPhone OS ([\d_]+)/i)
          return ["ios", match[1].tr("_", ".")] if match

          match = user_agent.match(/iPad; CPU OS ([\d_]+)/i)
          return ["ios", match[1].tr("_", ".")] if match

          match = user_agent.match(/Mac OS X ([\d_]+)/i)
          return ["macos", match[1].tr("_", ".")] if match

          return ["linux", nil] if user_agent.match?(/linux/i)

          [UNKNOWN, nil]
        end

        ##
        # @param user_agent [String]
        # @return [Array<String, String, nil>]
        def detect_device(user_agent:)
          return ["apple", "iphone"] if user_agent.match?(/iphone/i)
          return ["apple", "ipad"] if user_agent.match?(/ipad/i)

          match = user_agent.match(/Android [\d\.]+; ([^;\)]+)/i)
          return ["android", match[1].strip] if match

          [nil, nil]
        end

        ##
        # @param user_agent [String]
        # @return [String]
        def detect_platform(user_agent:)
          return "ios" if user_agent.match?(/iphone|ipad|ipod/i)
          return "android" if user_agent.match?(/android/i)
          return "windows" if user_agent.match?(/windows/i)
          return "macos" if user_agent.match?(/macintosh|mac os x/i)
          return "linux" if user_agent.match?(/linux/i)

          UNKNOWN
        end

        ##
        # @return [Hash]
        def unknown_result
          SentinelTracker::Providers::ClientDevice::Schema.empty_result.merge(
            device_type: UNKNOWN,
            device_vendor: nil,
            device_model: nil,
            os_name: UNKNOWN,
            os_version: nil,
            browser_name: UNKNOWN,
            browser_version: nil,
            platform: UNKNOWN,
            bot: false,
            payload: payload_for(user_agent: nil)
          )
        end

        ##
        # @param user_agent [String, nil]
        # @return [Hash]
        def payload_for(user_agent:)
          {
            provider_name: provider_name,
            user_agent: user_agent
          }.compact
        end
      end
    end
  end
end

SentinelTracker::ClientDeviceEnrichmentRegistry.register(
  provider_name: SentinelTracker::Providers::UserAgentParser::Provider::PROVIDER_NAME,
  provider_builder: lambda do |configuration, provider_options|
    max_user_agent_length = provider_options.fetch("max_user_agent_length", 2_000).to_i

    SentinelTracker::Providers::UserAgentParser::Provider.new(
      max_user_agent_length: max_user_agent_length,
      logger: configuration.logger
    )
  end
)
