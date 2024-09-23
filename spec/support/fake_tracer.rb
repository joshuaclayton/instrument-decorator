class FakeTracer
  def initialize
    @spans = []
  end

  attr_accessor :name

  def in_span(name, &block)
    span = Span.new(name:)

    begin
      block.call(span)
    ensure
      @spans << span
    end
  end

  def has_tracked_span?(name, args: nil, kwargs: nil, error: nil)
    @spans.any? do |span|
      name_matches = span.name == name
      args_matches = if args
                       span.args == args
                     else
                       true
                     end

      kwargs_matches = if kwargs
                       span.kwargs == kwargs
                     else
                       true
                     end

      error_matches = if error
                        span.errored_with?(error)
                      else
                        true
                      end

      name_matches && args_matches && kwargs_matches && error_matches
    end
  end

  class Span
    attr_reader :name

    def initialize(name:)
      @name = name
      @attributes = {}
      @error = nil
    end

    def record_exception(error)
      @error = error
    end

    def status=(status)
    end

    def add_attributes(attributes)
      @attributes.merge!(attributes)
    end

    def args
      @attributes[Instrument::Decorator.config.args_label]
    end

    def kwargs
      @attributes[Instrument::Decorator.config.kwargs_label]
    end

    def errored_with?(error)
      if @error
        @error.instance_of?(error.class) && @error.message == error.message
      else
        false
      end
    end
  end
end
