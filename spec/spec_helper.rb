# frozen_string_literal: true

require_relative "support/open_telemetry"
require "instrument/decorator"
require_relative "support/fake_tracer"
require_relative "support/generate_class"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    Instrument::Decorator.reset

    if ENV["WITH_OPEN_TELEMETRY"] == "true"
      Instrument::Decorator.configure do |config|
        config.for_open_telemetry
      end
    end
  end

  config.around do |example|
    if ENV["WITH_OPEN_TELEMETRY"] == "true"
      tracer = OpenTelemetry.tracer_provider.tracer("instrument-decorator-test-run")

      tracer.in_span(example.id) do
        example.run
      end
    else
      example.run
    end
  end
end
