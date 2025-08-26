module BlueFactory
  module Interactions
    def on_interactions(&block)
      @interactions_handler = block
    end

    attr_accessor :interactions_handler
  end
end
