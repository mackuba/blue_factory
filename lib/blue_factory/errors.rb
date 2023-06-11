require 'sinatra/base'

class BlueFactory < Sinatra::Base
  class InvalidRequestError < StandardError
    attr_reader :error_type

    def initialize(message, error_type = nil)
      super(message)
      @error_type = error_type
    end
  end
end
