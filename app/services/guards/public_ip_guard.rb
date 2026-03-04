module SentinelTracker
  module Shared
    ##
    # Проверяет, является ли IP публичным и пригодным для внешней телеметрии.
    class PublicIpGuard
      PRIVATE_NETWORKS = [
        IPAddr.new("10.0.0.0/8"),
        IPAddr.new("127.0.0.0/8"),
        IPAddr.new("169.254.0.0/16"),
        IPAddr.new("172.16.0.0/12"),
        IPAddr.new("192.168.0.0/16"),
        IPAddr.new("::1/128"),
        IPAddr.new("fc00::/7"),
        IPAddr.new("fe80::/10")
      ].freeze

      class << self
        ##
        # @param ip [String, nil]
        # @return [Boolean]
        def public?(ip:)
          return false if ip.nil?

          address = IPAddr.new(ip)
          PRIVATE_NETWORKS.none? { |network| network.include?(address) }
        rescue IPAddr::InvalidAddressError
          false
        end
      end
    end
  end
end
