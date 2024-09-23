RSpec.describe Instrument::Decorator::Config do
  describe "#display_name" do
    it "handles instance methods" do
      expect(described_class.new.display_name(
        class_name: "Foo",
        method_name: "bar",
        method_type: :instance
      )).to eq("Foo#bar")
    end
  end

  describe "overriding configuration" do
    it "allows for setting trace generation" do
      config = described_class.new
      provided_namespace = nil
      provided_version = nil
      return_value = double("tracer")

      config.on_generate_tracer do |namespace, version = nil|
        provided_namespace = namespace
        provided_version = version
        return_value
      end

      tracer = config.generate_tracer("foo", "1.2.3")

      expect(tracer).to eq(return_value)
      expect(provided_namespace).to eq("foo")
      expect(provided_version).to eq("1.2.3")
    end
  end
end
