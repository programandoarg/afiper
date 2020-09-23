# frozen_string_literal: true

module Afiper
  class Configuration
    attr_accessor :wsfe_homologacion, :padron_homologacion

    def initialize
      @error_handlers = nil
    end
  end
end
