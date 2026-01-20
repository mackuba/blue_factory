module BlueFactory
  ##
  # Adds interaction callback support to the host class/module.
  module Interactions
    ##
    # Registers a callback for incoming interactions.
    #
    # @yieldparam interactions [Array<Interaction>] incoming interactions
    # @yieldparam context [RequestContext] request context for the interaction
    # @return [void]
    def on_interactions(&block)
      @interactions_handler = block
    end

    # @return [Proc, nil] the current interaction handler
    attr_accessor :interactions_handler
  end
end
