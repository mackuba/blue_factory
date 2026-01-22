module BlueFactory

  #
  # @api private
  #
  # Adds a helper for configuring supported properties to {BlueFactory}.
  # Use these APIs through the main {BlueFactory} module, not directly.
  #

  module Configurable
    def self.extended(target)
      target.instance_variable_set('@properties', [])
    end

    def configurable(*properties)
      @properties ||= []
      @properties += properties.map(&:to_sym)
      singleton_class.attr_reader(*properties)
    end

    #
    # Sets a configurable property to the given value.
    #
    # @api public
    # @param property [String, Symbol] configuration key
    # @param value [Object] value to assign
    # @raise [NoMethodError] if no such property is defined
    #
    def set(property, value)
      if @properties.include?(property.to_sym)
        self.instance_variable_set("@#{property}", value)
      else
        raise NoMethodError, "No such property: #{property}"
      end
    end

    private :configurable
    private_class_method :extended
  end
end
