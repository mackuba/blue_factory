module BlueFactory

  #
  # @api private
  #
  # Adds configuration for an interactions handler to {BlueFactory}.
  # Use these APIs through the main {BlueFactory} module, not directly.
  #

  module Interactions

    #
    # Returns the currently configured feed interactions handler.
    #
    # @api public
    # @see Interaction
    # @yieldparam interactions [Array<Interaction>] one or more received interactions
    # @yieldparam context [RequestContext] HTTP request context, including e.g. user auth info
    #
    def on_interactions(&block)
      @interactions_handler = block
    end

    #
    # Returns the currently configured feed interactions handler.
    #
    # @api public
    # @see Interaction
    # @see #on_interactions
    # @return [Proc, nil]
    #
    def interactions_handler
      @interactions_handler
    end

    #
    # Registers a callback for incoming feed interactions.
    #
    # @api public
    # @see Interaction
    # @see #on_interactions
    #
    def interactions_handler=(block)
      @interactions_handler = block
    end
  end
end
