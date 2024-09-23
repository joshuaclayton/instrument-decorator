# frozen_string_literal: true

RSpec.describe Instrument::Decorator do
  it "has a version number" do
    expect(Instrument::Decorator::VERSION).not_to be nil
  end

  def configure_tracer
    tracer = FakeTracer.new

    Instrument::Decorator.configure do |config|
      config.on_generate_tracer do |namespace, version|
        tracer.name = namespace
        tracer
      end
    end

    tracer
  end

  it "tracks methods with no args" do
    tracer = configure_tracer
    generate_class("MethodWithNoArgs") do
      include Instrument::Decorator[:override]

      instrument def awesome
        "awesome"
      end
    end

    expect(MethodWithNoArgs.new.awesome).to eq("awesome")
    expect(tracer.name).to eq("override")
    expect(tracer).to have_tracked_span(
      "MethodWithNoArgs#awesome"
    )
  end

  it "tracks methods with args" do
    tracer = configure_tracer

    generate_class("MethodWithArgs") do
      include Instrument::Decorator[:override]

      instrument def awesome(arg1, arg2)
        "awesome"
      end
    end

    expect(MethodWithArgs.new.awesome(:foo, 1)).to eq("awesome")
    expect(tracer).to have_tracked_span(
      "MethodWithArgs#awesome",
      args: [:foo, 1].to_json
    )
  end

  it "tracks methods with kwargs" do
    tracer = configure_tracer

    generate_class("MethodWithKwargs") do
      include Instrument::Decorator[:override]

      instrument def awesome(arg1:, arg2:)
        "awesome"
      end
    end

    expect(MethodWithKwargs.new.awesome(arg1: :foo, arg2: 1)).to eq("awesome")
    expect(tracer).to have_tracked_span(
      "MethodWithKwargs#awesome",
      kwargs: {arg1: :foo, arg2: 1}.to_json
    )
  end

  it "tracks methods when no namespace was provided" do
    tracer = configure_tracer

    generate_class("NoNamespace") do
      include Instrument::Decorator

      instrument def awesome
        "awesome"
      end
    end

    expect(NoNamespace.new.awesome).to eq("awesome")
    expect(tracer.name).to eq("{unknown}")
  end

  it "tracks when the method raises" do
    tracer = configure_tracer

    generate_class("MethodThatRaises") do
      include Instrument::Decorator[:override]

      instrument def say_hi(to:)
        raise "nope: #{to}"
      end
    end

    expect do
      MethodThatRaises.new.say_hi(to: "Josh")
    end.to raise_error("nope: Josh")

    expect(tracer).to have_tracked_span(
      "MethodThatRaises#say_hi",
      kwargs: {to: "Josh"}.to_json,
      error: RuntimeError.new("nope: Josh")
    )
  end

  it "tracks nested methods" do
    tracer = configure_tracer

    generate_class("Thing") do
      include Instrument::Decorator[:override]

      def initialize(nested: false)
        @values = rand(100).times.map { rand(100) }
        @other_things = []
        @random_count = rand(1..5)

        if !nested
          @other_things = rand(1..5).times.map { Thing.new(nested: true) }
        end
      end

      instrument def other_things
        @other_things
      end

      instrument def values
        random_count.times do
          sleep 0.1
        end

        @values
      end

      instrument def random_count
        @random_count
      end
    end

    thing = Thing.new
    thing.other_things.each do |t|
      t.values.inspect
    end

    expect(tracer).to have_tracked_span("Thing#other_things")
    expect(tracer).to have_tracked_span("Thing#values")
    expect(tracer).to have_tracked_span("Thing#random_count")
  end

  it "works with the null tracer" do
    generate_class("Thing") do
      include Instrument::Decorator

      instrument_class_method def self.test_class
        "test_class output"
      end

      instrument def test_instance
        "test_instance output"
      end

      instrument def test_exception
        raise "awesome"
      end
    end

    expect(Thing.test_class).to eq("test_class output")
    expect(Thing.new.test_instance).to eq("test_instance output")
    expect do
      Thing.new.test_exception
    end.to raise_error(RuntimeError, "awesome")
  end

  it "tracks class methods" do
    tracer = configure_tracer
    generate_class("ClassMethod") do
      include Instrument::Decorator

      instrument_class_method def self.awesome
        "awesome"
      end
    end

    expect(ClassMethod.awesome).to eq("awesome")
    expect(tracer).to have_tracked_span(
      "ClassMethod.awesome"
    )
  end

  it "works with inheritance via superclass" do
    tracer = configure_tracer
    generate_class("ClassWithAwesome") do
      include Instrument::Decorator[:override]

      instrument def awesome
        "awesome"
      end
    end

    generate_class("Subclass", ClassWithAwesome) do
      def awesome_from_subclass
        awesome
      end
    end

    expect(Subclass.new.awesome).to eq("awesome")
    expect(tracer).to have_tracked_span("ClassWithAwesome#awesome")
  end

  it "works with inheritance via module includes" do
    tracer = configure_tracer
    my_module = Module.new
    def my_module.name
      "MyModule"
    end

    my_module.module_eval do
      include Instrument::Decorator[:override]

      instrument def awesome
        "awesome"
      end
    end

    generate_class("SubclassViaModule") do
      include my_module

      def awesome_from_subclass
        awesome
      end
    end

    expect(SubclassViaModule.new.awesome).to eq("awesome")
    expect(tracer).to have_tracked_span("MyModule#awesome")
  end

  it "including a module that includes instrumentation does not provide instrument out of the box" do
    my_module = Module.new do
      include Instrument::Decorator[:override]
    end

    expect do
      generate_class("Awesome") do
        include my_module

        instrument def awesome
          "awesome"
        end
      end
    end.to raise_error(NoMethodError, /^undefined method .instrument. for Awesome/)
  end
end
