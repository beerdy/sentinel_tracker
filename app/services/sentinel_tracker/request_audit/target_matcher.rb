module SentinelTracker
  ##
  # Определяет, относится ли request к целевому пользователю.
  class TargetMatcher
    ##
    # @return [SentinelTracker::Configuration]
    attr_reader :configuration

    ##
    # @param configuration [SentinelTracker::Configuration]
    # @return [void]
    def initialize(configuration:)
      @configuration = configuration
    end

    ##
    # @param request [ActionDispatch::Request]
    # @return [Hash, nil]
    def call(request:)
      return unless configuration.enabled

      user_id = resolve_user_id(request)
      login = resolve_login(request)

      matched_target = match_by_user_id(user_id)
      return matched_target if matched_target

      match_by_login(login, user_id)
    end
    private

    ##
    # @param request [ActionDispatch::Request]
    # @return [Object]
    def resolve_user_id(request)
      configuration.user_resolver.call(request: request)
    end

    ##
    # @param request [ActionDispatch::Request]
    # @return [String, nil]
    def resolve_login(request)
      normalize_login(configuration.login_resolver.call(request: request))
    end

    ##
    # @param user_id [Object]
    # @return [Hash, nil]
    def match_by_user_id(user_id)
      return if configuration.target_user_id.nil?
      return unless user_id.to_i == configuration.target_user_id.to_i

      {
        matched_by: "target_user_id",
        target_user_id: configuration.target_user_id,
        target_login: configuration.normalized_target_login
      }
    end

    ##
    # @param login [String, nil]
    # @param user_id [Object]
    # @return [Hash, nil]
    def match_by_login(login, user_id)
      target_login = configuration.normalized_target_login
      return if target_login.nil?
      return unless login == target_login

      {
        matched_by: "target_login",
        target_user_id: normalize_user_id(user_id),
        target_login: target_login
      }
    end

    ##
    # @param user_id [Object]
    # @return [Integer, nil]
    def normalize_user_id(user_id)
      return if user_id.nil?

      user_id.to_i
    end

    ##
    # @param login [Object]
    # @return [String, nil]
    def normalize_login(login)
      return if login.nil?

      normalized_login = login.to_s.strip.downcase
      return if normalized_login.empty?

      normalized_login
    end
  end
end
