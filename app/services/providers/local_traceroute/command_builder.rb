module SentinelTracker
  module Providers
    module LocalTraceroute
      ##
      # Собирает безопасную argv-команду для local_traceroute provider.
      class CommandBuilder
        TRACEROUTE_QUERY_COUNT ||= "1".freeze
        TRACEROUTE_MAX_TTL ||= "8".freeze
        DEFAULT_COMMAND_PATH ||= "/usr/sbin/traceroute".freeze
        FALLBACK_COMMAND_PATHS ||= ["/usr/sbin/traceroute", "/usr/bin/traceroute", "/bin/traceroute"].freeze

        ##
        # @return [String]
        attr_reader :traceroute_command_path

        ##
        # @param traceroute_command_path [String]
        # @return [void]
        def initialize(traceroute_command_path:)
          @traceroute_command_path = traceroute_command_path
        end

        ##
        # @param ip [String, nil]
        # @return [Array<String>, nil]
        def call(ip:)
          return if ip.nil?
          command_path = resolved_command_path
          return if command_path.nil?
          return unless SentinelTracker::Shared::PublicIpGuard.public?(ip: ip)

          [
            command_path,
            "-q", TRACEROUTE_QUERY_COUNT,
            "-m", TRACEROUTE_MAX_TTL,
            ip
          ]
        end
        private

        ##
        # @return [String, nil]
        def resolved_command_path
          candidates = [traceroute_command_path, *FALLBACK_COMMAND_PATHS].compact.uniq
          candidates.find { |command_path| File.executable?(command_path) }
        end
      end
    end
  end
end
