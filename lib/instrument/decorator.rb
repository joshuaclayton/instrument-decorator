# frozen_string_literal: true

require_relative "decorator/version"
require_relative "decorator/track"
require_relative "decorator/config"
require_relative "decorator/null_tracer"
require "active_support/all"

module Instrument
  module Decorator
    extend ActiveSupport::Concern
    class Error < StandardError; end

    mattr_accessor :config

    def self.configure(&block)
      self.config ||= Config.new

      block.call(config)
    end

    def self.reset
      self.config = Config.new
    end

    def self.[](custom)
      Interior[custom]
    end

    included do
      include Interior[nil]
    end

    module Interior
      extend ActiveSupport::Concern

      mattr_accessor :namespace

      private :namespace=

      def self.[](custom)
        self.namespace = custom

        self
      end

      class_methods do
        def instrument_class_method(method_name)
          __instrument__(method_name, class_name: name, method_type: :class, target: singleton_class)
        end

        def instrument(method_name)
          __instrument__(method_name, class_name: name, method_type: :instance, target: self)
        end

        def __instrument__(method_name, class_name:, method_type:, target:)
          namespace = Interior.namespace

          __instrumentation_module__(target).class_eval do
            define_method(method_name) do |*args, **kwargs, &block|
              tracer = Instrument::Decorator.config.generate_tracer(namespace)

              display_name = Instrument::Decorator.config.display_name(
                class_name:,
                method_name:,
                method_type:
              )

              track = Instrument::Decorator::Track.new(name: method_name, args:, kwargs:, block:, namespace:)

              tracer.in_span(display_name) do |span|
                track.start(span:)
                super(*args, **kwargs, &block)
              rescue => e
                track.track_error(e)
                raise e
              ensure
                track.finish
              end
            end
          end
        end

        def __instrumentation_module__(target)
          if target.const_defined?(:Instrumentation)
            target.const_get(:Instrumentation)
          else
            target.const_set(:Instrumentation, Module.new).tap do
              target.prepend(_1)
            end
          end
        end
      end
    end
  end
end
