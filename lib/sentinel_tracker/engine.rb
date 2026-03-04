require "rails/engine"

module SentinelTracker
  ##
  # Rails Engine для автоматического подключения middleware и job-классов.
  class Engine < ::Rails::Engine
    isolate_namespace SentinelTracker

    initializer "sentinel_tracker.middleware" do |app|
      app.middleware.use SentinelTracker::RequestAuditMiddleware
    end
  end
end
