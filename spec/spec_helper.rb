require "bundler/setup"
require "logger"
require "active_job"
require "sentinel_tracker"

ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.before do
    SentinelTracker.reset_configuration!
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end
end
