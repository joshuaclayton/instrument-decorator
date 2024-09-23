module GenerateClass
  def generate_class(class_name = "GenericClass#{rand(1000)}", klass = Class.new, &block)
    klass.define_singleton_method(:name) do
      class_name
    end

    klass.class_exec(&block)

    Object.const_set(class_name, klass)

    @defined_constants << class_name

    Object.const_get(class_name)
  end
end

RSpec.configure do |config|
  config.include GenerateClass

  config.around do |example|
    @defined_constants = []

    example.run

    @defined_constants.each do |const|
      Object.send(:remove_const, const)
    end
  end
end
