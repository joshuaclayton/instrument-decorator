module Instrument::Decorator
  class Config
    def initialize
      @generate_tracer = ->(provided_namespace, version = nil) do
        Instrument::Decorator::NullTracer.new(provided_namespace, version)
      end

      @generate_error_status = ->(error) do
        Instrument::Decorator::NullTracer.error_status(error)
      end
    end

    def for_open_telemetry
      @generate_tracer = ->(provided_namespace, version = nil) do
        OpenTelemetry.tracer_provider.tracer(provided_namespace, version)
      end

      @generate_error_status = ->(error) do
        OpenTelemetry::Trace::Status.error(error.to_s)
      end
    end

    def generate_tracer(provided_namespace, version = nil)
      @generate_tracer.call(namespace(provided_namespace), version)
    end

    def on_generate_tracer(&block)
      @generate_tracer = block
    end

    def track_error(span:, error:)
      span.record_exception(error)
      span.status = @generate_error_status.call(error)
    end

    def track_call(span:, args:, kwargs:)
      span.add_attributes(
        args_label => format_args(args),
        kwargs_label => format_kwargs(kwargs)
      )
    end

    def namespace(value)
      (value || "{unknown}").to_s
    end

    def display_name(class_name:, method_name:, method_type:)
      "#{class_name || "{anonymous}"}#{(method_type == :class) ? "." : "#"}#{method_name}"
    end

    def format_args(args)
      args.to_json
    end

    def format_kwargs(kwargs)
      kwargs.to_json
    end

    def args_label
      "method.args"
    end

    def kwargs_label
      "method.kwargs"
    end
  end
end
