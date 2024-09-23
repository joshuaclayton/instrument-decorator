module Instrument::Decorator
  class Track
    attr_reader :name, :args, :kwargs, :block, :namespace, :error

    def initialize(name:, args:, kwargs:, block:, namespace:)
      @name = name
      @args = args
      @kwargs = kwargs
      @block = block
      @namespace = namespace
      @span = nil
      @error = nil
      @started_at = nil
    end

    def track_error(error)
      Instrument::Decorator.config.track_error(span:, error:)

      @error = error
    end

    def duration
      if @ended_at && @started_at
        @ended_at - @started_at
      end
    end

    def start(span:)
      @span = span
      Instrument::Decorator.config.track_call(span:, args:, kwargs:)

      @started_at = Time.now
      self
    end

    def finish
      @ended_at = Time.now
    end

    private

    attr_reader :span
  end
end
