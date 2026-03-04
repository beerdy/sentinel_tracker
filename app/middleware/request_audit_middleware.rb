module SentinelTracker
  ##
  # Middleware, перехватывающий request и enqueue'ящий аудит для target-user.
  class RequestAuditMiddleware
    ##
    # @return [#call]
    attr_reader :app
    ##
    # @return [SentinelTracker::RequestContextExtractor]
    attr_reader :request_context_extractor
    ##
    # @return [SentinelTracker::TargetMatcher]
    attr_reader :target_matcher
    ##
    # @return [Logger]
    attr_reader :logger

    ##
    # @param app [#call]
    # @param request_context_extractor [SentinelTracker::RequestContextExtractor, nil]
    # @param target_matcher [SentinelTracker::TargetMatcher, nil]
    # @param logger [Logger, nil]
    # @return [void]
    def initialize(app, request_context_extractor: nil, target_matcher: nil, logger: nil)
      configuration = SentinelTracker.configuration

      @app = app
      @request_context_extractor = request_context_extractor || RequestContextExtractor.new
      @target_matcher = target_matcher || TargetMatcher.new(configuration: configuration)
      @logger = logger || configuration.logger
    end

    ##
    # @param env [Hash]
    # @return [Array(Integer, Hash, #each)]
    def call(env)
      request = ActionDispatch::Request.new(env)
      payload = request_context_extractor.call(request: request)

      response = app.call(env)
      match = target_matcher.call(request: request)
      enqueue_event(payload, match) if match
      response
    rescue StandardError => error
      log_error(error)
      app.call(env)
    end

    private

    ##
    # @param payload [Hash]
    # @param match [Hash]
    # @return [void]
    def enqueue_event(payload, match)
      SentinelTracker::SecurityEvents::PersistJob.perform_later(payload.merge(match))
    end

    ##
    # @param error [StandardError]
    # @return [void]
    def log_error(error)
      logger.error("[sentinel_tracker] middleware failure: #{error.class}: #{error.message}")
    end
  end
end
