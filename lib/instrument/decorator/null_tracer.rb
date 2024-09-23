module Instrument::Decorator
  class NullTracer
    def initialize(*)
    end

    def in_span(*)
      yield(NullSpan.new)
    end

    def self.error_status(error)
      error.to_s
    end

    class NullSpan
      def record_exception(*)
      end

      def status=(*)
      end

      def add_attributes(*)
      end
    end
  end
end
