module SentinelTracker
  module Resolvers
    ##
    # Универсальный resolver текущего user_id для host-приложений.
    class CurrentUserIdResolver
      ##
      # @param request [ActionDispatch::Request]
      # @return [Integer, nil]
      def call(request:)
        user_id = current_user_id(request)
        return user_id if user_id.present?

        user_id = session_user_id(request)
        return user_id if user_id.present?

        devise_session_user_id(request, "warden.user.user.key") ||
          devise_session_user_id(request, "warden.user.client.key")
      end
      private

      ##
      # @param request [ActionDispatch::Request]
      # @return [Integer, nil]
      def current_user_id(request)
        current_user = request.env["warden"]&.user
        current_user = request.env["current_user"] if current_user.nil?

        controller_instance = request.env["action_controller.instance"]
        if current_user.nil? && controller_instance.respond_to?(:current_user)
          current_user = controller_instance.current_user
        end

        return unless current_user.respond_to?(:id)

        current_user.id
      end

      ##
      # @param request [ActionDispatch::Request]
      # @return [Integer, nil]
      def session_user_id(request)
        return unless request.session.respond_to?(:[])

        value = request.session[:user_id]
        return if value.blank?

        value.to_i
      end

      ##
      # @param request [ActionDispatch::Request]
      # @param key [String]
      # @return [Integer, nil]
      def devise_session_user_id(request, key)
        return unless request.session.respond_to?(:[])

        raw_value = request.session[key]
        return if raw_value.nil?

        first_value = raw_value.is_a?(Array) ? raw_value.first : raw_value
        first_value = first_value.first if first_value.is_a?(Array)
        return if first_value.nil?

        first_value.to_i
      end
    end
  end
end
