# frozen_string_literal: true

module Afiper
  # Configuracion del plugin
  class Configuration
    attr_writer :wsfe_homologacion, :padron_homologacion

    def initialize
      @error_handlers = nil
    end

    def wsfe_homologacion
      unless @wsfe_homologacion.in?([true, false])
        raise Error, 'Afiper: Error de configuración' \
                     'Agregar config/initializers/afiper.rb' \
                     '  Afiper.configure do |config|' \
                     '    config.wsfe_homologacion = true' \
                     '  end'
      end
      @wsfe_homologacion
    end

    def padron_homologacion
      unless @padron_homologacion.in?([true, false])
        raise Error, 'Afiper: Error de configuración' \
                     'Agregar config/initializers/afiper.rb' \
                     '  Afiper.configure do |config|' \
                     '    config.padron_homologacion = true' \
                     '  end'
      end
      @padron_homologacion
    end
  end
end
