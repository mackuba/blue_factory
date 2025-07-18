module BlueFactory
  module Configurable
    def self.extended(target)
      target.instance_variable_set('@properties', [])
    end

    def configurable(*properties)
      @properties ||= []
      @properties += properties.map(&:to_sym)
      singleton_class.attr_reader(*properties)
    end

    def set(property, value)
      if @properties.include?(property.to_sym)
        self.instance_variable_set("@#{property}", value)
      else
        raise NoMethodError, "No such property: #{property}"
      end
    end

    private :configurable
  end
end
