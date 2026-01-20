module BlueFactory
  ##
  # Adds configuration helpers to the extending class or module.
  module Configurable
    ##
    # Initializes configurable properties when the module is extended.
    #
    # @param target [Module] the extending module or class
    # @return [void]
    def self.extended(target)
      target.instance_variable_set('@properties', [])
    end

    def configurable(*properties)
      @properties ||= []
      @properties += properties.map(&:to_sym)
      singleton_class.attr_reader(*properties)
    end

    ##
    # Sets a configurable property on the receiving module.
    #
    # @param property [String, Symbol] configuration key
    # @param value [Object] value to assign
    # @return [void]
    # @raise [NoMethodError] if the property is not defined
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
