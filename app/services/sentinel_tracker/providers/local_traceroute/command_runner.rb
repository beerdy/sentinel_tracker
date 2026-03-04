require "open3"
require "timeout"

module SentinelTracker
  module Providers
    module LocalTraceroute
      ##
      # Запускает local_traceroute command с таймаутом и ограничением вывода.
      class CommandRunner
        DEFAULT_TIMEOUT_SECONDS = 15
        DEFAULT_MAX_OUTPUT_LENGTH = 20_000
        ##
        # @return [Integer]
        attr_reader :timeout_seconds
        ##
        # @return [Integer]
        attr_reader :max_output_length

        ##
        # @param timeout_seconds [Integer]
        # @param max_output_length [Integer]
        # @return [void]
        def initialize(timeout_seconds:, max_output_length:)
          @timeout_seconds = timeout_seconds
          @max_output_length = max_output_length
        end

        ##
        # @param command [Array<String>]
        # @return [Hash]
        def call(command:)
          stdout, stderr, process_status = nil

          Timeout.timeout(timeout_seconds) do
            stdout, stderr, process_status = Open3.capture3(*command)
          end

          build_result(
            status: process_status.success? ? "completed" : "failed",
            output: combined_output(stdout, stderr)
          )
        rescue Timeout::Error
          build_result(status: "failed", output: "network telemetry command timed out after #{timeout_seconds}s")
        rescue StandardError => error
          build_result(status: "failed", output: "#{error.class}: #{error.message}")
        end
        private

        ##
        # @param status [String]
        # @param output [String]
        # @return [Hash]
        def build_result(status:, output:)
          {
            network_telemetry_status: status,
            network_telemetry_output: output
          }
        end

        ##
        # @param stdout [String, nil]
        # @param stderr [String, nil]
        # @return [String]
        def combined_output(stdout, stderr)
          output = [stdout, stderr].compact.reject(&:empty?).join("\n")
          output[0...max_output_length]
        end
      end
    end
  end
end
