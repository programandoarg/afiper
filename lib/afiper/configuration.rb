module Afiper
  class Configuration
    attr_accessor :wsfe_homologacion
    attr_accessor :padron_homologacion

    def initialize
      @error_handlers = nil
    end
  end
end
