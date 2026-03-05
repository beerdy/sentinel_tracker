module SentinelTracker
  ##
  # Извлекает безопасный контекст запроса для дальнейшего аудита.
  class RequestContextExtractor
    FILTERED_VALUE ||= "[FILTERED]".freeze
    MAX_STRING_LENGTH ||= 2_000
    FILTERED_KEYS ||= %w[
      password
      password_confirmation
      token
      access_token
      refresh_token
      authorization
      cookie
    ].freeze

    ##
    # @param request [ActionDispatch::Request]
    # @return [Hash]
    def call(request:)
      {
        request_uuid: request_uuid(request),
        request_method: request.request_method,
        request_path: request.fullpath,
        ip: request.ip,
        x_forwarded_for: request_header(request, "HTTP_X_FORWARDED_FOR"),
        user_agent: truncate_value(request.user_agent),
        params: sanitized_params(request)
      }
    end
    private

    ##
    # @param request [ActionDispatch::Request]
    # @return [Hash]
    def sanitized_params(request)
      params = request.respond_to?(:filtered_parameters) ? request.filtered_parameters : request.params
      sanitize_value(params)
    end

    ##
    # @param value [Object]
    # @return [Object]
    def sanitize_value(value)
      if value.is_a?(Hash)
        sanitize_hash(value)
      elsif value.is_a?(Array)
        value.map { |item| sanitize_value(item) }
      elsif value.is_a?(String)
        truncate_value(value)
      else
        value
      end
    end

    ##
    # @param value [Hash]
    # @return [Hash]
    def sanitize_hash(value)
      value.each_with_object({}) do |(key, nested_value), result|
        normalized_key = key.to_s.downcase
        result[key] = FILTERED_KEYS.include?(normalized_key) ? FILTERED_VALUE : sanitize_value(nested_value)
      end
    end

    ##
    # @param value [String, nil]
    # @return [String, nil]
    def truncate_value(value)
      return if value.nil?

      value.to_s[0...MAX_STRING_LENGTH]
    end

    ##
    # @param request [ActionDispatch::Request]
    # @param name [String]
    # @return [Object]
    def request_header(request, name)
      return request.get_header(name) if request.respond_to?(:get_header)

      request.env[name]
    end

    ##
    # @param request [ActionDispatch::Request]
    # @return [String, nil]
    def request_uuid(request)
      return request.request_id if request.respond_to?(:request_id)
      return request.uuid if request.respond_to?(:uuid)

      request.env["action_dispatch.request_id"]
    end
  end
end
