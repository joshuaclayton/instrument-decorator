require "dotenv/load"

if ENV["WITH_OPEN_TELEMETRY"] == "true"
  require "opentelemetry/sdk"
  require "opentelemetry/instrumentation/all"
  require "opentelemetry/exporter/otlp"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = "instrument-decorator-tests"
    c.use_all
    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new
      )
    )
  end
end
