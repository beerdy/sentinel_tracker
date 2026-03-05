module SentinelTracker
  module Providers
    module LocalTraceroute
      ##
      # Локальный network telemetry provider на базе traceroute.
      class Provider
        PROVIDER_NAME = "local_traceroute".freeze
        ##
        # @return [SentinelTracker::Providers::LocalTraceroute::CommandBuilder]
        attr_reader :network_telemetry_command_builder
        ##
        # @return [SentinelTracker::Providers::LocalTraceroute::CommandRunner]
        attr_reader :network_telemetry_command_runner

        ##
        # @param network_telemetry_command_builder [SentinelTracker::Providers::LocalTraceroute::CommandBuilder]
        # @param network_telemetry_command_runner [SentinelTracker::Providers::LocalTraceroute::CommandRunner]
        # @return [void]
        def initialize(network_telemetry_command_builder:, network_telemetry_command_runner:)
          @network_telemetry_command_builder = network_telemetry_command_builder
          @network_telemetry_command_runner = network_telemetry_command_runner
        end

        ##
        # @param ip [String, nil]
        # @return [Hash]
        def call(ip:)
          command = network_telemetry_command_builder.call(ip: ip)
          return skipped_result unless command

          network_telemetry_command_runner.call(command: command).merge(
            provider_name: provider_name,
            payload: {
              command: command
            }
          )
        end

        ##
        # @return [String]
        def provider_name
          PROVIDER_NAME
        end

        private

        ##
        # @return [Hash]
        def skipped_result
          {
            network_telemetry_status: "skipped",
            network_telemetry_output: "network telemetry command unavailable for current environment",
            provider_name: provider_name,
            payload: {
              reason: "command_unavailable"
            }
          }
        end
      end
    end
  end
end

SentinelTracker::NetworkTelemetryRegistry.register(
  provider_name: SentinelTracker::Providers::LocalTraceroute::Provider::PROVIDER_NAME,
  provider_builder: lambda do |configuration, provider_options|
    SentinelTracker::Providers::LocalTraceroute::Provider.new(
      network_telemetry_command_builder: SentinelTracker::Providers::LocalTraceroute::CommandBuilder.new(
        traceroute_command_path: provider_options.fetch(
          "command_path",
          SentinelTracker::Providers::LocalTraceroute::CommandBuilder::DEFAULT_COMMAND_PATH
        )
      ),
      network_telemetry_command_runner: SentinelTracker::Providers::LocalTraceroute::CommandRunner.new(
        timeout_seconds: provider_options.fetch(
          "timeout_seconds",
          SentinelTracker::Providers::LocalTraceroute::CommandRunner::DEFAULT_TIMEOUT_SECONDS
        ),
        max_output_length: provider_options.fetch(
          "max_output_length",
          SentinelTracker::Providers::LocalTraceroute::CommandRunner::DEFAULT_MAX_OUTPUT_LENGTH
        )
      )
    )
  end
)
