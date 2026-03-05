module SentinelTracker
  module Resolvers
    ##
    # Универсальный resolver текущего login для host-приложений.
    class CurrentLoginResolver
      TOKEN_SEPARATOR ||= "_".freeze

      ##
      # @param request [ActionDispatch::Request]
      # @return [String, nil]
      def call(request:)
        login = current_user_login(request)
        return login if login.present?

        login = token_login(header_token(request))
        return login if login.present?

        login = token_login(cookie_token(request))
        return login if login.present?

        login_params(request)
      end
      private

      ##
      # @param request [ActionDispatch::Request]
      # @return [String, nil]
      def current_user_login(request)
        current_user = request.env["warden"]&.user
        current_user = request.env["current_user"] if current_user.nil?

        controller_instance = request.env["action_controller.instance"]
        if current_user.nil? && controller_instance.respond_to?(:current_user)
          current_user = controller_instance.current_user
        end

        return unless current_user.respond_to?(:login)

        current_user.login
      end

      ##
      # @param value [String, nil]
      # @return [String, nil]
      def token_login(value)
        return if value.blank?
        return unless value.include?(TOKEN_SEPARATOR)

        value.to_s.rpartition(TOKEN_SEPARATOR).first.presence
      end

      ##
      # @param request [ActionDispatch::Request]
      # @return [String, nil]
      def header_token(request)
        return request.get_header("HTTP_AUTHORIZATION") if request.respond_to?(:get_header)

        request.env["HTTP_AUTHORIZATION"]
      end

      ##
      # @param request [ActionDispatch::Request]
      # @return [String, nil]
      def cookie_token(request)
        cookies = request.respond_to?(:cookie_jar) ? request.cookie_jar : request.cookies
        return if cookies.nil?

        cookies["token"]
      rescue StandardError
        nil
      end

      ##
      # @param request [ActionDispatch::Request]
      # @return [String, nil]
      def login_params(request)
        params = request.params
        login_payload = params["login"] || params[:login]
        return login_payload["user"] || login_payload[:user] if login_payload.respond_to?(:[])

        user_payload = params["user"] || params[:user]
        return user_payload["login"] || user_payload[:login] if user_payload.respond_to?(:[])

        login_payload.presence
      end
    end
  end
end
